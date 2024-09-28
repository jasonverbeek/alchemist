#!/bin/sh

# Sets: PROJECT_DIR, IMAGE_NAME, DEV_IMAGE_LOCAL_NAME, ARTIFACTS_DIR
SCRIPT_DIR="$(realpath $(dirname $0))"
. "${SCRIPT_DIR}/vars.sh"

TARGET_ARCH=""
case "$1" in
amd64)
  TARGET_ARCH="amd64"
  ;;
arm64)
  TARGET_ARCH="arm64"
  ;;
*)
  echo "No architeture given (either amd64 or arm64)"
  echo
  echo "Usage $0 <ARCH> [--keep]"
  exit 1
  ;;
esac

if [ "$2" == "--keep" ]; then
  # TODO: Not having `--rm` doesn't seem to make a difference..? Why?
  podman run --arch ${TARGET_ARCH} -it -v ${PROJECT_DIR}:/var/src "${REGISTRY_DNS_NAME}/${IMAGE_NAME}" /bin/sh
else
  podman run --arch ${TARGET_ARCH} -it --rm -v ${PROJECT_DIR}:/var/src "${REGISTRY_DNS_NAME}/${IMAGE_NAME}" /bin/sh
fi
