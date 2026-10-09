# macOS-specific helpers for the macOS build/run/stop/uninstall-clean scripts.
# Source shared/build-run.conf before this file (it provides the configuration values).

# Load the shared helpers (colours and print functions).
source "$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/../../shared/common.sh"

# Dotted version comparison: success when $1 >= $2.
version_ge() {
    awk -v a="$1" -v b="$2" 'BEGIN {
        na = split(a, A, /[.]/); nb = split(b, B, /[.]/); n = (na > nb ? na : nb)
        for (i = 1; i <= n; i++) {
            av = (i <= na ? A[i] : 0) + 0
            bv = (i <= nb ? B[i] : 0) + 0
            if (av > bv) exit 0
            if (av < bv) exit 1
        }
        exit 0
    }'
}

# Exit unless running on macOS (Apple silicon, macOS 26+).
require_macos() {
    local macos_ver
    if [ "$(uname -s)" != "Darwin" ]; then
        error "This script runs on macOS only (detected: $(uname -s))."
        exit 1
    fi
    if [ "$(uname -m)" != "arm64" ]; then
        error "Apple Container CLI requires an Apple silicon Mac (arm64); detected $(uname -m)."
        exit 1
    fi
    macos_ver="$(sw_vers -productVersion 2>/dev/null || true)"
    if [ -n "${macos_ver}" ] && ! version_ge "${macos_ver}" "${MACOS_MIN}"; then
        error "Apple Container CLI requires macOS ${MACOS_MIN} or newer (detected ${macos_ver})."
        exit 1
    fi
}

# Exit unless the Apple Container CLI is installed.
require_container_cli() {
    if ! command -v container >/dev/null 2>&1; then
        error "Apple Container CLI is not installed."
        warn "Run the build script first: bash tools/builds/targets/macos/build-image-macos.sh"
        exit 1
    fi
}

# Exit unless the image is built.
require_image() {
    if ! container image list --quiet 2>/dev/null | grep -qF "${IMAGE_NAME}"; then
        error "Image '${IMAGE_NAME}' is not built."
        warn "Run the build script first: bash tools/builds/targets/macos/build-image-macos.sh"
        exit 1
    fi
}

# Success when the named container exists (running or stopped).
container_exists() {
    container list --all --quiet 2>/dev/null | grep -qx "${CONTAINER_NAME}"
}

# Success when the named container is currently running.
container_running() {
    container list --quiet 2>/dev/null | grep -qx "${CONTAINER_NAME}"
}
