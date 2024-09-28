# WARNING: calling script must have at least `set -u` (nounset) set.
PROJECT_DIR=$(dirname $SCRIPT_DIR)
IMAGE_NAME="rust-base:latest"
REGISTRY_DNS_NAME="registry.localhost8080.org"
ARTIFACTS_DIR="$PROJECT_DIR/artifacts"
