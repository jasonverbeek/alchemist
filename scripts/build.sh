#!/bin/sh
# TODO: re-enable below, and fix wrong-arch-container chosen, because ...?
#set -eu

# Sets: PROJECT_DIR, DEV_IMAGE_NAME, DEV_IMAGE_LOCAL_NAME, ARTIFACTS_DIR
SCRIPT_DIR="$(realpath $(dirname $0))"
. "${SCRIPT_DIR}/vars.sh"

# Ensure environment is clean:
cargo clean
test -d "${ARTIFACTS_DIR}" && rm -rf "${ARTIFACTS_DIR}"

echo
echo '=================='
echo '= AMD / INTEL 64 ='
echo '=================='
echo
podman run --platform=linux/amd64 -v ${PROJECT_DIR}:/var/src --rm "${DEV_IMAGE_LOCAL_NAME}" cargo build --release
test -f ${PROJECT_DIR}/target/release/alchemist || echo "No build artifact found, aborting" && exit 1
cp -p ${PROJECT_DIR}/target/release/alchemist ${ARTIFACTS_DIR}/alchemist-linux-x86_64

cargo clean # Clean before next arch build.
echo
echo '=================='
echo '= ARM 64 ='
echo '=================='
echo
podman run --platform=linux/arm64 -v ${PROJECT_DIR}:/var/src --rm "${DEV_IMAGE_LOCAL_NAME}" cargo build --release
test -f ${PROJECT_DIR}/target/release/alchemist || echo "No build artifact found, aborting" && exit 1
cp -p ${PROJECT_DIR}/target/release/alchemist ${ARTIFACTS_DIR}/alchemist-linux-arm64
