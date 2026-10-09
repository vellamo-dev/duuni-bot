#!/usr/bin/env bash
# Stop and remove the container, then remove the image.

set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# Load the shared configuration and helpers.
source "${SCRIPT_DIR}/shared/build-run.conf"
source "${SCRIPT_DIR}/shared/common.sh"

# Checks.
require_podman

# Stop the container first (via the dedicated script).
info "Stopping the container ..."
bash "${SCRIPT_DIR}/stop-container-podman.sh"

# Remove the container.
if container_exists; then
    info "Removing container '${CONTAINER_NAME}' ..."
    podman rm -f "${CONTAINER_NAME}"
    ok "Container '${CONTAINER_NAME}' removed."
else
    info "Container '${CONTAINER_NAME}' does not exist; nothing to remove."
fi

# Remove the application image.
if podman image exists "${IMAGE_NAME}" 2>/dev/null; then
    info "Removing image '${IMAGE_NAME}' ..."
    podman rmi -f "${IMAGE_NAME}"
    ok "Image '${IMAGE_NAME}' removed."
else
    info "Image '${IMAGE_NAME}' is not present; nothing to remove."
fi

# Remove the base/helper images pulled by the build.
for img in ${BASE_IMAGES}; do
    if podman image exists "${img}" 2>/dev/null; then
        info "Removing helper image '${img}' ..."
        podman rmi -f "${img}"
    fi
done

# Remove dangling (intermediate) images left by the multi-stage build.
podman image prune -f 2>/dev/null || true

ok "Cleanup complete."
