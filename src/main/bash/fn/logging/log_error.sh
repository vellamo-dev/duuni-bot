#!/usr/bin/env bash
# Store error log

if [ -z "${PATH_SCR_FN_LGE:-}" ]; then
    PATH_SCR_FN_LGE="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly PATH_SCR_FN_LGE
fi

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_LGE}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_LGE}/../conf/paths.sh"
source "${PATH_SCR_FN_LGE}/log_common.sh"

# Store error information
dbot_error() {
    local feature message log_path
    feature="${1:-}"
    shift 2>/dev/null || true
    message="${*:-}"
    log_path="$(path_of_log_error_file 2>/dev/null || true)"
    dbot_write "ERROR" "${feature}" "${message}" "${log_path}"
    return 0
}
