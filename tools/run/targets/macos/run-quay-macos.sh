#!/usr/bin/env bash
# Run the ready-made Duuni-Bot image from quay.io on macOS.
# Uses Apple's Container CLI and pulls the image when it is not present.
#
# Usage:
#   run-quay-macos.sh            pull, create, and run the container
#   run-quay-macos.sh --stop     stop the container if it exists
#   run-quay-macos.sh --remove   remove the container and image if they exist

set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR

source "${SCRIPT_DIR}/../shared/run.conf"
source "${SCRIPT_DIR}/../shared/common.sh"

# Adapter: macOS with Apple's Container CLI.
require_platform() {
    if [ "$(uname -s)" != "Darwin" ]; then
        error "This script runs on macOS only (detected: $(uname -s))."
        exit 1
    fi
    if ! command -v container >/dev/null 2>&1; then
        error "Apple Container CLI is not installed."
        exit 1
    fi
}

image_exists()     { container image list --quiet 2>/dev/null | grep -qF "${IMAGE_NAME}"; }
pull_image()       { container image pull "${IMAGE_NAME}"; }
container_exists() { container list --all --quiet 2>/dev/null | grep -qx "${CONTAINER_NAME}"; }

# The published quay.io image is currently built for linux/amd64 only, so ask
# Apple's Container CLI for that platform explicitly (it will emulate it).
# Drop this once the image is published multi-arch (amd64 + arm64).
PLATFORM="linux/amd64"

create_container() {
    common_create_args
    container create --name "${CONTAINER_NAME}" \
        --platform "${PLATFORM}" \
        --user root \
        "${COMMON_ARGS[@]}" \
        "${IMAGE_NAME}"
}

start_container()    { container start "${CONTAINER_NAME}" 2>/dev/null || true; }
stop_container_cmd() { container stop "${CONTAINER_NAME}" || true; }
remove_container()   { container delete --force "${CONTAINER_NAME}" >/dev/null 2>&1 || true; }
remove_image()       { container image delete --force "${IMAGE_NAME}" >/dev/null 2>&1 || true; }

# Apple's Container CLI maps bind mounts to root, so make the directory
# writable by every user.
prepare_data_dir() {
    chmod -R a+rwX "${DATA_DIR}" 2>/dev/null || sudo chmod -R a+rwX "${DATA_DIR}" || \
        warn "Could not make ${DATA_DIR} writable. Run manually: chmod -R a+rwX ${DATA_DIR}"
}

LOGS_CMD="container logs -f ${CONTAINER_NAME}"
STOP_CMD="container stop ${CONTAINER_NAME}"
DELETE_CMD="container delete ${CONTAINER_NAME}"
EXEC_CMD="container exec ${CONTAINER_NAME} bash /opt/duuni-bot/duuni-bot.sh"

source "${SCRIPT_DIR}/../shared/run-common.sh"

main "${@}"
