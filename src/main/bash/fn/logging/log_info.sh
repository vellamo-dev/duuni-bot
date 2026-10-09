#!/usr/bin/env bash
# Store informative log

if [ -z "${PATH_SCR_FN_LGI:-}" ]; then
    PATH_SCR_FN_LGI="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly PATH_SCR_FN_LGI
fi

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_LGI}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_LGI}/../conf/paths.sh"
source "${PATH_SCR_FN_LGI}/log_common.sh"

# Store information
dbot_log() {
    local feature message log_path
    feature="${1:-}"
    shift 2>/dev/null || true
    message="${*:-}"
    log_path="$(path_of_log_info_file 2>/dev/null || true)"
    dbot_write "INFO" "${feature}" "${message}" "${log_path}"
    return 0
}
