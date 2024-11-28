# Alchemist Lua Spec v0 (proposal)

## Introduction

Lua scripts can be written in the `alchemist.toml` or in a separate `.lua` file in your project

Lua files can be stored anywhere in your project, just supply a relative path from the alchemist.toml file.

However its recommended to use `alchemist/lua` if you plan to add the scripts to the repository and `.alchemist/lua` if you plan to keep them local to your machine.

## Globals

The following globals are available to the Lua scripts:
- `tasks` - a table of all tasks in the `alchemist.toml`, even the hidden ones.
- `commands` - a list of the tasks the user wishes to run. NOTE: these are not arguments/parameters
- `os` - a string representing the operating system. Either `windows`, `linux`, or the far superior `macos` (just kidding, it's actually named `darwin`)


## Task

A task can be `exec`uted or `spawn`ed

### exec(allow_fail) -> exit_code

`allow_fail` allow a task to fail. (optional, default: false)

Executes a task and waits for it to finish.

### spawn(allow_fail) -> handle

`allow_fail` allow a task to fail. (optional, default: false)

Executes a task and returns a handle. A handle is supposed to be `:join()`-ed.

Any unjoined handles/tasks will be canceled when the lua runtime finishes.

## Handle

A handle can be used to wait for a task to finish using `join()`.

If a handle is not joined the task may be canceled before it is finished.

### join() -> exit_code

Waits for a task to finish and returns the exit code.

### Example:

```lua
t1 = tasks["long_running_task1"]:spawn()
t2 = tasks["long_running_task2"]:spawn()

exit_code3 = tasks["hello_world"]:exec()

exit_code2 = t2:join()
```

This example will run `long_running_task1` and `long_running_task2` in the background.

Then it will run `hello_world` and wait for it to finish.

Finally it will wait for `long_running_task2` to finish. And cancel `long_running_task1` if it hasn't finished yet.
