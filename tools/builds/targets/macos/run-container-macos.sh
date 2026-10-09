#!/usr/bin/env bash
# Run the Duuni-Bot container using Apple's Container CLI.
# Requires macOS 26+ (Tahoe) on Apple Silicon.

set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# Load the shared configuration and helpers.
source "${SCRIPT_DIR}/shared/build-run.conf"
source "${SCRIPT_DIR}/shared/common.sh"

# macOS only — stop immediately on any other system.
require_macos

# Use DB_ENV_PATH_DATA for the data directory when it is set and is an existing directory.
if [ -n "${DB_ENV_PATH_DATA:-}" ] && [ -d "${DB_ENV_PATH_DATA}" ]; then
    DATA_DIR="${DB_ENV_PATH_DATA}"
fi

# Create the container without starting it.
create_container() {
    info "Creating container '${CONTAINER_NAME}' ..."
    # Run as root: Apple's Container CLI maps bind mounts to root:root inside
    # the container, so a non-root user cannot write to the mounted data dir.
    container create --name "${CONTAINER_NAME}" \
        --user root \
        --volume "${DATA_DIR}:/data" \
        --env "CRON_SCHEDULE=${CRON_SCHEDULE}" \
        --env "DB_ENV_DB_SLEEP=${DB_ENV_DB_SLEEP:-}" \
        --env "DB_ENV_DB_BROWSER=${DB_ENV_DB_BROWSER:-}" \
        --env "DB_ENV_ENABLE_ST_EK2=${DB_ENV_ENABLE_ST_EK2:-}" \
        "${IMAGE_NAME}"
}

# Start the container by name.
start_container() {
    info "Starting container '${CONTAINER_NAME}' ..."
    container start "${CONTAINER_NAME}" 2>/dev/null || true
}

# Checks.
require_container_cli
require_image

# Ensure the system service is running.
container system start >/dev/null 2>&1 || true

# Prepare the data directory. Apple's Container CLI bind mounts map host
# ownership to root, so makes the directory world-writable for the non-root
# container user.
mkdir -p "${DATA_DIR}"
info "Making ${DATA_DIR} writable by the container ..."
chmod -R a+rwX "${DATA_DIR}" 2>/dev/null || sudo chmod -R a+rwX "${DATA_DIR}" || \
    warn "Could not make ${DATA_DIR} writable. Run manually: chmod -R a+rwX ${DATA_DIR}"

# Create the container or reuse/recreate an existing one.
if container_exists; then
    warn "Container '${CONTAINER_NAME}' already exists."
    read -r -p "Stop, delete, and recreate it? [y/N] " answer
    case "${answer}" in
    [yY]*)
        info "Removing the existing container ..."
        container delete --force "${CONTAINER_NAME}" >/dev/null 2>&1 || true
        create_container
        start_container
        ;;
    *)
        info "Keeping the existing container and starting it ..."
        start_container
        ;;
    esac
else
    create_container
    start_container
fi

echo
ok "Container '${CONTAINER_NAME}' is running."
echo
echo "Follow logs:  container logs -f ${CONTAINER_NAME}"
echo "List:         container list"
echo "Stop:         container stop ${CONTAINER_NAME}"
echo "Delete:       container delete ${CONTAINER_NAME}"
echo
