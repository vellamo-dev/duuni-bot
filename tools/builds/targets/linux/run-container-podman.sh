#!/usr/bin/env bash
# Run the Duuni-Bot container using Podman.
# Runs on Linux (any distribution) and on macOS where Podman is installed.
# Podman must already be installed; the script stops if it is missing.

set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# Load the shared configuration and helpers.
source "${SCRIPT_DIR}/shared/build-run.conf"
source "${SCRIPT_DIR}/shared/common.sh"

# Podman must be installed; stop immediately otherwise.
require_podman

# Use DB_ENV_PATH_DATA for the data directory when it is set and is an existing directory.
if [ -n "${DB_ENV_PATH_DATA:-}" ] && [ -d "${DB_ENV_PATH_DATA}" ]; then
    DATA_DIR="${DB_ENV_PATH_DATA}"
fi

# Create the container without starting it.
create_container() {
    info "Creating container '${CONTAINER_NAME}' ..."
    podman create --name "${CONTAINER_NAME}" \
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
    podman start "${CONTAINER_NAME}" 2>/dev/null || true
}

# Ensure the image is built.
require_image

# Prepare the data directory. The container runs as the non-root user UID 10001,
# so a bind-mounted host directory must be owned by that user.
mkdir -p "${DATA_DIR}"
info "Making ${DATA_DIR} writable by the container user (UID 10001) ..."
sudo chown -R "${CONTAINER_UID}:${CONTAINER_UID}" "${DATA_DIR}" 2>/dev/null || \
    warn "Could not chown. Run manually: sudo chown -R ${CONTAINER_UID}:${CONTAINER_UID} ${DATA_DIR}"

# Create the container or reuse/recreate an existing one.
if container_exists; then
    warn "Container '${CONTAINER_NAME}' already exists."
    read -r -p "Stop, delete, and recreate it? [y/N] " answer
    case "${answer}" in
    [yY]*)
        info "Removing the existing container ..."
        podman rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
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
echo "Follow logs:  podman logs -f ${CONTAINER_NAME}"
echo "List:         podman ps"
echo "Stop:         podman stop ${CONTAINER_NAME}"
echo "Delete:       podman rm -f ${CONTAINER_NAME}"
echo
