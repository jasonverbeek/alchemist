#!/bin/sh
# TODO: re-enable below, and fix wrong-arch-container chosen, because ...?
set -eu

# Sets: PROJECT_DIR, IMAGE_NAME, REGISTRY_DNS_NAME, ARTIFACTS_DIR
SCRIPT_DIR="$(realpath $(dirname $0))"
. "${SCRIPT_DIR}/vars.sh"

# Ensure environment is clean:
test -d "${ARTIFACTS_DIR}" && rm -rf "${ARTIFACTS_DIR}"
mkdir -p ${ARTIFACTS_DIR}

echo
echo '=================='
echo '= AMD / INTEL 64 ='
echo '=================='
echo
podman run --platform=linux/amd64 -v "${PROJECT_DIR}:/var/src" -e CARGO_TARGET_DIR="target-amd64" --rm "${REGISTRY_DNS_NAME}/${IMAGE_NAME}" cargo clean
podman run --platform=linux/amd64 -v "${PROJECT_DIR}:/var/src" -e CARGO_TARGET_DIR="target-amd64" --rm "${REGISTRY_DNS_NAME}/${IMAGE_NAME}" cargo build --release
if test -f "${PROJECT_DIR}/target-amd64/release/alchemist"; then
  cp -p "${PROJECT_DIR}/target-amd64/release/alchemist" "${ARTIFACTS_DIR}/alchemist-linux-x86_64"
else
  echo "No build artifact found, aborting"
  exit 1
fi

echo
echo '=================='
echo '= ARM 64 ='
echo '=================='
echo
podman run --platform=linux/arm64 -v "${PROJECT_DIR}:/var/src" -e CARGO_TARGET_DIR="target-arm64" --rm "${REGISTRY_DNS_NAME}/${IMAGE_NAME}" cargo clean
podman run --platform=linux/arm64 -v "${PROJECT_DIR}:/var/src" -e CARGO_TARGET_DIR="target-arm64" --rm "${REGISTRY_DNS_NAME}/${IMAGE_NAME}" cargo build --release
if test -f "${PROJECT_DIR}/target-arm64/release/alchemist"; then
  cp -p "${PROJECT_DIR}/target-arm64/release/alchemist" "${ARTIFACTS_DIR}/alchemist-linux-arm64"
else
  echo "No build artifact found, aborting"
  exit 1
fi
