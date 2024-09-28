# WARNING: calling script must have at least `set -u` (nounset) set.
PROJECT_DIR=$(dirname $SCRIPT_DIR)
DEV_IMAGE_NAME="alchemist-build:latest"
REGISTRY_DNS_NAME="registry.localhost8080.org"
ARTIFACTS_DIR="$PROJECT_DIR/artifacts"
