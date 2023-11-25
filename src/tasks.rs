use std::collections::HashMap;
use std::process::Command;

use crate::config::AlchemistConfig;
use crate::error::{AlchemistError, AssertionError, Result};

use crate::cli::terminal;

use oh_no::ResultContext;
use serde::Deserialize;
pub trait RunnableTask {
    fn run<S: ToString>(&self, task_name: S, config: &AlchemistConfig) -> Result<()>;
}

#[derive(Debug, Deserialize, Clone)]
#[serde(deny_unknown_fields)]
/// Alchemist BasicTask type is a simple task with a command and optional args
/// Example:
/// ```
/// [tasks.my_task]
/// command = "echo"
/// args = ["hello", "world"]
/// ```
pub struct AlchemistBasicTask {
    #[allow(dead_code)]
    command: String,
    #[allow(dead_code)]
    args: Option<Vec<String>>,
    env: Option<HashMap<String, String>>,
    pub hide: Option<bool>,
}

#[derive(Debug, Deserialize, Clone)]
#[serde(deny_unknown_fields)]
/// Alchemist SerialTasks type can be a set of multiple basic tasks
///
/// These tasks are executed in the given order
///
///
/// Example:
/// ```
/// [tasks.my_task]
/// serial_tasks = ["my_other_task1", "my_other_task2"]
/// hide = false
///
/// ```
pub struct AlchemistSerialTasks {
    #[allow(dead_code)]
    serial_tasks: Vec<String>,
    hide: Option<bool>,
}

#[derive(Debug, Deserialize, Clone)]
#[serde(deny_unknown_fields)]
/// Alchemist ParallelTasks type can be a set of multiple basic tasks
///
/// These tasks are executed in parallel.
///
///
/// Example:
/// ```
/// [tasks.my_task]
/// serial_tasks = ["my_other_task1", "my_other_task2"]
/// hide = false
///
/// ```
pub struct AlchemistParallelTasks {
    parallel_tasks: Vec<String>,
    hide: Option<bool>,
}

#[derive(Debug, Deserialize, Clone)]
#[serde(deny_unknown_fields)]
/// Alchemist ShellTask type can run a script in `sh`
///
///
/// Example:
/// ```
/// [tasks.my_task]
/// shell_script = '''
/// VAR="value"
/// echo my var is $VAR
/// '''
///
/// ```
pub struct AlchemistShellTask {
    shell_script: String,
    hide: Option<bool>,
}

impl RunnableTask for AlchemistBasicTask {
    fn run<S: ToString>(&self, task_name: S, _config: &AlchemistConfig) -> Result<()> {
        let task_name = task_name.to_string();
        let mut cmd = Command::new(&self.command);

        if let Some(env_var) = &self.env {
            cmd.envs(env_var);
        }

        let command_str = if let Some(args) = &self.args {
            cmd.args(args);
            format!("{} {}", &self.command, args.join(" "))
        } else {
            self.command.to_string()
        };
        terminal::info(format!("Running command {}", command_str));
        let mut child = cmd.spawn().error_msg(format!("Starting basic task {task_name} with command `{command_str}` either not found or insufficient permissions to run."))?;
        let exit_code = child.wait().error_msg(format!( "While running basic task {task_name}, command `{command_str}` failed (non-zero exit code)."))?;

        if !exit_code.success() {
            return AssertionError(
                format!( "While running basic task {task_name}, command `{command_str}` failed (non-zero exit code).")
            ).into();
        }
        terminal::ok(format!("Finished command {}", command_str));
        Ok(())
    }
}

impl RunnableTask for AlchemistSerialTasks {
    fn run<S: ToString>(&self, task_name: S, config: &AlchemistConfig) -> Result<()> {
        let task_name = task_name.to_string();
        terminal::info(format!(
            "Running serial task '{}' which is a collection of {:?}",
            task_name, self.serial_tasks
        ));
        for sub_task_name in &self.serial_tasks {
            let task = config.tasks.get(sub_task_name).ok_or::<AlchemistError>(
                AssertionError(format!(
                    "Serial task '{task_name}' has an invalid subtask '{sub_task_name}'"
                ))
                .into(),
            )?;
            task.run(sub_task_name, config)?
        }
        terminal::ok(format!("Finished serial task '{task_name}'"));
        Ok(())
    }
}

// TODO: Error handling for failed parallel tasts & stdout/-err (think...)
impl RunnableTask for AlchemistParallelTasks {
    fn run<S: ToString>(&self, task_name: S, config: &AlchemistConfig) -> crate::error::Result<()> {
        let task_name = task_name.to_string();
        terminal::info(format!(
            "Running parallel task '{}' which is a collection of {:?}",
            task_name, self.parallel_tasks
        ));
        let mut background_jobs = Vec::<std::thread::JoinHandle<crate::error::Result<()>>>::new();
        for sub_task_name in &self.parallel_tasks {
            match config.tasks.get(sub_task_name) {
                Some(task) => {
                    let ctask = task.clone();
                    let cfg = config.clone();
                    let name = sub_task_name.clone();
                    background_jobs.push(std::thread::spawn(move || -> Result<()> {
                        ctask.run(name, &cfg)?;
                        Ok(())
                    }));
                    Ok(())
                }
                None => AssertionError(format!(
                    "Parallel task '{task_name}' has an invalid subtask '{sub_task_name}'"
                ))
                .into(),
            }?;
        }
        // Here we join all threads and handle results later
        let mut has_error = false;
        for result in background_jobs
            .into_iter()
            .map(|h| h.join().expect("Can not join thread"))
            .collect::<Vec<Result<()>>>()
        {
            if let Err(e) = result {
                terminal::error(e);
                has_error = true;
            }
        }
        if has_error {
            AssertionError("One or more errors occoured in parallel tasks".into()).into()
        } else {
            terminal::ok(format!("Finished parallel task '{task_name}'"));
            Ok(())
        }
    }
}

impl RunnableTask for AlchemistShellTask {
    fn run<S: ToString>(&self, task_name: S, _config: &AlchemistConfig) -> Result<()> {
        let task_name = task_name.to_string();
        let mut cmd = Command::new("sh");

        cmd.arg("-c");
        cmd.arg(&self.shell_script);

        terminal::info(format!("Running shell script {}", task_name));
        let mut child = cmd
            .spawn()
            .error_msg(format!("Failed to start shell script {task_name}."))?;
        let exit_code = child.wait().error_msg(format!(
            "Shell script '{task_name}' can not be awaited (won't stop)."
        ))?;

        if !exit_code.success() {
            return AssertionError(format!(
                "Shell script '{task_name}' exited with non-zero exit code."
            ))
            .into();
        }
        terminal::ok(format!("Finished shell script {task_name}"));
        Ok(())
    }
}

#[derive(Debug, Deserialize, Clone)]
#[serde(untagged)]
/// An enum of multiple variations of tasks within the alchemist.toml
///
///
/// This is used as multiple types for serde (de)serialization
///
/// doing this allows us to have multiple types of tasks without a complex configuration format
pub enum AlchemistTaskType {
    AlchemistBasicTask(AlchemistBasicTask),
    AlchemistSerialTasks(AlchemistSerialTasks),
    AlchemistParallelTasks(AlchemistParallelTasks),
    AlchemistShellTask(AlchemistShellTask),
}

impl AlchemistTaskType {
    pub fn is_shown(&self) -> bool {
        match self {
            Self::AlchemistBasicTask(v) => !v.hide.unwrap_or(false),
            Self::AlchemistSerialTasks(v) => !v.hide.unwrap_or(false),
            Self::AlchemistParallelTasks(v) => !v.hide.unwrap_or(false),
            Self::AlchemistShellTask(v) => !v.hide.unwrap_or(false),
        }
    }
}

impl RunnableTask for AlchemistTaskType {
    fn run<T: ToString>(&self, task_name: T, config: &AlchemistConfig) -> Result<()> {
        match self {
            AlchemistTaskType::AlchemistBasicTask(task) => task.run(task_name, config),
            AlchemistTaskType::AlchemistSerialTasks(task) => task.run(task_name, config),
            AlchemistTaskType::AlchemistParallelTasks(task) => task.run(task_name, config),
            AlchemistTaskType::AlchemistShellTask(task) => task.run(task_name, config),
        }
    }
}
