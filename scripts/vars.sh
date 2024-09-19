# WARNING: calling script must have at least `set -u` (nounset) set.
PROJECT_DIR=$(dirname $SCRIPT_DIR)
DEV_IMAGE_NAME="alchemist-build:latest"
DEV_IMAGE_LOCAL_NAME="localhost/${DEV_IMAGE_NAME}"
ARTIFACTS_DIR="$PROJECT_DIR/artifacts"
