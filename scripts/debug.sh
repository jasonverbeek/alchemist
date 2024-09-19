#!/bin/sh

SCRIPT_DIR="$(realpath $(dirname $0))"
PROJECT_DIR=$(dirname $SCRIPT_DIR)
. "${SCRIPT_DIR}/vars.sh"

if [ "$1" == "--keep" ]; then
  # TODO: Not having `--rm` doesn't seem to make a difference..? Why?
  podman run --arch amd64 -it -v ${PROJECT_DIR}:/var/src "${DEV_IMAGE_NAME}" /bin/sh
else
  podman run --arch amd64 -it --rm -v ${PROJECT_DIR}:/var/src "${DEV_IMAGE_NAME}" /bin/sh
fi
