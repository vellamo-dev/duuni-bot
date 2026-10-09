# Linux (Podman) helpers for the Podman build/run/stop/uninstall-clean scripts.
# Source shared/build-run.conf before this file (it provides the configuration values).

# Load the shared helpers (colours and print functions).
source "$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/../../shared/common.sh"

# Exit unless Podman is installed. This is the one hard requirement: the
# scripts do not care about the Linux distribution, only that Podman exists.
require_podman() {
    if ! command -v podman >/dev/null 2>&1; then
        error "Podman is not installed."
        warn "Install Podman first (https://podman.io), then run this script again."
        exit 1
    fi
}

# Exit unless the image is built.
require_image() {
    if ! podman image exists "${IMAGE_NAME}" 2>/dev/null; then
        error "Image '${IMAGE_NAME}' is not built."
        warn "Run the build script first: bash tools/builds/targets/linux/build-image-podman.sh"
        exit 1
    fi
}

# Success when the named container exists (running or stopped).
container_exists() {
    podman container exists "${CONTAINER_NAME}" 2>/dev/null
}

# Success when the named container is currently running.
container_running() {
    podman ps --format '{{.Names}}' 2>/dev/null | grep -qx "${CONTAINER_NAME}"
}
