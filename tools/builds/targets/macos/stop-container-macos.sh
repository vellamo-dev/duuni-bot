#!/usr/bin/env bash
# Stop the Duuni-Bot container (if it is running).

set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# Load the shared configuration and helpers.
source "${SCRIPT_DIR}/shared/build-run.conf"
source "${SCRIPT_DIR}/shared/common.sh"

# Platform check.
require_macos

# If the CLI is not installed, no container can be running.
if ! command -v container >/dev/null 2>&1; then
    info "Apple Container CLI is not installed, so no container is running."
    exit 0
fi

# Nothing to stop when the container does not exist.
if ! container_exists; then
    info "Container '${CONTAINER_NAME}' does not exist."
    exit 0
fi

# Already stopped.
if ! container_running; then
    info "Container '${CONTAINER_NAME}' is already stopped."
    exit 0
fi

# Stop it.
info "Stopping container '${CONTAINER_NAME}' ..."
container stop "${CONTAINER_NAME}"

# Report the final status.
if container_running; then
    warn "Container '${CONTAINER_NAME}' is still running."
    exit 1
fi
ok "Container '${CONTAINER_NAME}' stopped."
