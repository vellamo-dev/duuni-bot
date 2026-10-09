#!/usr/bin/env bash
# Build the Duuni-Bot container image using Podman.
# Runs on Linux (any distribution) and on macOS where Podman is installed.
# Podman must already be installed; the script stops if it is missing.

set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../" && pwd -P)"

# Load the shared configuration and helpers.
source "${SCRIPT_DIR}/shared/build-run.conf"
source "${SCRIPT_DIR}/shared/common.sh"

# Podman must be installed; stop immediately otherwise.
require_podman

# Build the image. BuildKit sets TARGETARCH for the current host.
cd "${REPO_ROOT}"
ok "Building ${IMAGE_NAME} ..."
podman build -t "${IMAGE_NAME}" .

# Point to the run command.
echo
ok "Built ${IMAGE_NAME}"
echo
echo "Run the container:"
echo "  podman run -d --name ${CONTAINER_NAME} -v ${DATA_DIR}:/data ${IMAGE_NAME}"
echo
