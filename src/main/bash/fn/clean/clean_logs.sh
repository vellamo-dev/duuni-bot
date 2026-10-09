#!/usr/bin/env bash
# Delete info and error log files older than DB_LOG_RETENTION_DAYS.

PATH_SCR_FN_CLG="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_CLG

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_CLG}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_CLG}/../conf/paths.sh"

# Delete info and error log files older than DB_LOG_RETENTION_DAYS days.
cleanup_old_logs() {
    local days info_dir error_dir
    days="${DB_LOG_RETENTION_DAYS:-30}"
    case "${days}" in
    '' | *[!0-9]*) days=30 ;;
    esac
    [ "${days}" -gt 0 ] || return 0
    info_dir="$(path_of_log_info_dir 2>/dev/null || true)"
    error_dir="$(path_of_log_error_dir 2>/dev/null || true)"
    if [ -n "${info_dir}" ]; then
        find "${info_dir}" -type f -name '*.log' -mtime +"${days}" -delete 2>/dev/null || true
    fi
    if [ -n "${error_dir}" ]; then
        find "${error_dir}" -type f -name '*.log' -mtime +"${days}" -delete 2>/dev/null || true
    fi
    return 0
}
