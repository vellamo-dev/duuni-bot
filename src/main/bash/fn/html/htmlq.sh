#!/usr/bin/env bash
# htmlq tool requirement.

if [ -z "${PATH_SCR_FN_HLQ:-}" ]; then
    PATH_SCR_FN_HLQ="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly PATH_SCR_FN_HLQ
fi

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_HLQ}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_HLQ}/../logging/log.sh"

# Stop when the htmlq application is not installed.
require_htmlq() {
    if ! command -v htmlq >/dev/null 2>&1; then
        print_error "Missing htmlq. macOS: brew install htmlq. Linux: cargo install htmlq, or the release binary from https://github.com/mgdm/htmlq/releases"
        dbot_error "Tooling" "htmlq is not installed"
        return 1
    fi
}
