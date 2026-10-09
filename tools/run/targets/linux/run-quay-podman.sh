#!/usr/bin/env bash
# Run the ready-made Duuni-Bot image from quay.io with Podman.
# Pulls the image when it is not present.
#
# Usage:
#   run-quay-podman.sh            pull, create, and run the container
#   run-quay-podman.sh --stop     stop the container if it exists
#   run-quay-podman.sh --remove   remove the container and image if they exist

set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR

source "${SCRIPT_DIR}/../shared/run.conf"
source "${SCRIPT_DIR}/../shared/common.sh"

# Adapter: Podman.
require_platform() {
    if ! command -v podman >/dev/null 2>&1; then
        error "Podman is not installed."
        exit 1
    fi
}

image_exists()     { podman image exists "${IMAGE_NAME}" 2>/dev/null; }
pull_image()       { podman pull "${IMAGE_NAME}"; }
container_exists() { podman container exists "${CONTAINER_NAME}" 2>/dev/null; }

create_container() {
    common_create_args
    podman create --name "${CONTAINER_NAME}" \
        "${COMMON_ARGS[@]}" \
        "${IMAGE_NAME}"
}

start_container()    { podman start "${CONTAINER_NAME}" 2>/dev/null || true; }
stop_container_cmd() { podman stop "${CONTAINER_NAME}" || true; }
remove_container()   { podman rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true; }
remove_image()       { podman rmi -f "${IMAGE_NAME}" >/dev/null 2>&1 || true; }

# The container runs as UID ${CONTAINER_UID}.
prepare_data_dir() {
    sudo chown -R "${CONTAINER_UID}:${CONTAINER_UID}" "${DATA_DIR}" 2>/dev/null || \
        warn "Could not chown. Run manually: sudo chown -R ${CONTAINER_UID}:${CONTAINER_UID} ${DATA_DIR}"
}

LOGS_CMD="podman logs -f ${CONTAINER_NAME}"
STOP_CMD="podman stop ${CONTAINER_NAME}"
DELETE_CMD="podman rm -f ${CONTAINER_NAME}"
EXEC_CMD="podman exec ${CONTAINER_NAME} bash /opt/duuni-bot/duuni-bot.sh"

source "${SCRIPT_DIR}/../shared/run-common.sh"

main "${@}"
