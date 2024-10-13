#!/bin/sh
set -eu

# Sets: PROJECT_DIR, IMAGE_NAME, REGISTRY_DNS_NAME, ARTIFACTS_DIR
SCRIPT_DIR="$(realpath $(dirname $0))"
. "${SCRIPT_DIR}/vars.sh"

function usage {
  echo
  echo "Usage $(basename $0) <ARCH> [--keep]"
  exit 1
}

TARGET_ARCH=""
if [ $# -ge 1 ]; then
  case "$1" in
  amd64)
    TARGET_ARCH="amd64"
    ;;
  arm64)
    TARGET_ARCH="arm64"
    ;;
  *)
    echo "No correct architecture given (either amd64 or arm64), got: $1"
    usage
    ;;
  esac
else
  echo "No architecture given (either amd64 or arm64)."
  usage
fi

ADDITIONAL_OPTIONS="--rm"
if [ $# -eq 2 ]; then
  if [ "$2" == "--keep" ]; then
    ADDITIONAL_OPTIONS=""
  else
    echo "Unsupported flag: $2"
    usage
  fi
fi

podman run --arch "${TARGET_ARCH}" -it ${ADDITIONAL_OPTIONS} -v "${PROJECT_DIR}:/var/src" "${REGISTRY_DNS_NAME}/${IMAGE_NAME}" /bin/sh
