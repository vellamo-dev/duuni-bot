#!/usr/bin/env bash
# Build the Duuni-Bot container image using Apple's Container CLI.
# Requires macOS 26+ (Tahoe) on Apple silicon.

set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../" && pwd -P)"

# Load the shared configuration and helpers.
source "${SCRIPT_DIR}/shared/build-run.conf"
source "${SCRIPT_DIR}/shared/common.sh"

# macOS only — stop immediately on any other system.
require_macos

# Detect the latest Apple Container CLI release and install its signed package.
install_container_cli() {
    local release_json version installer_url tmp pkg
    info "Looking up the latest Apple Container CLI release ..."
    release_json="$(curl -fsSL "${CONTAINER_CLI_API}")"
    version="$(printf '%s' "${release_json}" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)"
    installer_url="$(printf '%s' "${release_json}" | grep -oE 'https://[^"]*installer-signed\.pkg' | head -1)"
    if [ -z "${version}" ] || [ -z "${installer_url}" ]; then
        error "Could not determine the latest release from the GitHub API."
        return 1
    fi
    info "Latest release: ${version}"
    tmp="$(mktemp -d)"
    pkg="${tmp}/installer.pkg"
    info "Downloading ${installer_url} ..."
    curl -fsSL -o "${pkg}" "${installer_url}"
    info "Installing (administrator password required) ..."
    sudo installer -pkg "${pkg}" -target /
    rm -rf "${tmp}"
    ok "Apple Container CLI ${version} installed."
}

# Ensure Apple Container CLI is installed.
if ! command -v container >/dev/null 2>&1; then
    warn "Apple Container CLI is not installed."
    read -r -p "Install it from https://github.com/apple/container ? [y/N] " answer
    case "${answer}" in
    [yY]*) install_container_cli ;;
    *) error "Apple Container CLI is required to build the image. Aborting."; exit 1 ;;
    esac
fi

# Make sure the container system service is running.
# (The first run may prompt to install the Linux kernel.)
info "Starting the container system service ..."
container system start || true

# Build the image. BuildKit sets TARGETARCH=arm64 for this host.
cd "${REPO_ROOT}"
ok "Building ${IMAGE_NAME} ..."
container build -t "${IMAGE_NAME}" .

# Point to the run script.
echo
ok "Built ${IMAGE_NAME}"
echo
echo "Run the container:"
echo "  bash tools/builds/targets/macos/run-container-macos.sh"
echo
