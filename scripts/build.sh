#!/bin/sh
# TODO: re-enable below, and fix wrong-arch-container chosen, because ...?
set -eu

# Sets: PROJECT_DIR, IMAGE_NAME, REGISTRY_DNS_NAME, ARTIFACTS_DIR
SCRIPT_DIR="$(realpath $(dirname $0))"
. "${SCRIPT_DIR}/vars.sh"

# Ensure environment is clean:
cargo clean
test -d "${ARTIFACTS_DIR}" && rm -rf "${ARTIFACTS_DIR}"
mkdir -p ${ARTIFACTS_DIR}

echo
echo '=================='
echo '= AMD / INTEL 64 ='
echo '=================='
echo
podman run --platform=linux/amd64 -v "${PROJECT_DIR}:/var/src" --rm "${REGISTRY_DNS_NAME}/${IMAGE_NAME}" cargo build --release
if test -f "${PROJECT_DIR}/target/release/alchemist"; then
  cp -p "${PROJECT_DIR}/target/release/alchemist" "${ARTIFACTS_DIR}/alchemist-linux-x86_64"
else
  echo "No build artifact found, aborting"
  exit 1
fi

cargo clean # Clean before next arch build.
echo
echo '=================='
echo '= ARM 64 ='
echo '=================='
echo
podman run --platform=linux/arm64 -v "${PROJECT_DIR}:/var/src" --rm "${REGISTRY_DNS_NAME}/${IMAGE_NAME}" cargo build --release
if test -f "${PROJECT_DIR}/target/release/alchemist"; then
  cp -p "${PROJECT_DIR}/target/release/alchemist" "${ARTIFACTS_DIR}/alchemist-linux-arm64"
else
  echo "No build artifact found, aborting"
  exit 1
fi
