#!/usr/bin/env bash
# Resolve configured data paths

# Create a directory when it is missing.
ensure_dir() {
    local d="${1}"
    [ -n "${d}" ] || return 1
    [ -d "${d}" ] || mkdir -p -- "${d}"
}

# Expand a leading '~' into HOME.
expand_home() {
    local p="${1}"
    case "${p}" in
    \~) printf '%s\n' "${HOME}" ;;
    \~/*) printf '%s\n' "${HOME}/${p#\~/}" ;;
    *) printf '%s\n' "${p}" ;;
    esac
}

# Resolve ~, absolute, or project-relative path.
resolve_path() {
    local p
    p="$(expand_home "${1}")"
    case "${p}" in
    /*) printf '%s\n' "${p}" ;;
    *) printf '%s\n' "${DUUNI_ROOT}/${p#./}" ;;
    esac
}

# Resolve the data directory. Reuse DU_BOT_PATH_DATA when it is already set.
# A path inside DUUNI_ROOT gets /data appended.
path_of_data_dir() {
    local p
    if [ -n "${DU_BOT_PATH_DATA:-}" ]; then
        ensure_dir "${DU_BOT_PATH_DATA}"
        printf '%s\n' "${DU_BOT_PATH_DATA}"
        return 0
    fi
    p="$(resolve_path "${DB_PATH_DATA}")"
    case "${p}" in
    "${DUUNI_ROOT}" | "${DUUNI_ROOT}"/*)
        case "${p}" in
        */data | */data/*) ;;
        *) p="${p%/}/data" ;;
        esac
        ;;
    esac
    # bashsupport disable=BP2001
    export DU_BOT_PATH_DATA="${p}"
    ensure_dir "${DU_BOT_PATH_DATA}"
    printf '%s\n' "${DU_BOT_PATH_DATA}"
}

# Resolve a path under the configured data directory, without creating it.
resolve_data_item() {
    local base item="${1}"
    base="$(path_of_data_dir)"
    case "${item}" in
    \~ | \~/* | /*) resolve_path "${item}" ;;
    *) printf '%s\n' "${base}/${item#./}" ;;
    esac
}

# Resolve a data file path and ensure its parent directory exists.
path_of_data_item() {
    local resolved
    resolved="$(resolve_data_item "${1}")"
    ensure_dir "$(dirname -- "${resolved}")"
    printf '%s\n' "${resolved}"
}

# Resolve a data directory path and ensure the directory itself exists.
path_of_data_items_dir() {
    local resolved
    resolved="$(resolve_data_item "${1}")"
    ensure_dir "${resolved}"
    printf '%s\n' "${resolved}"
}

# Error logging directory: logging directory plus DB_DIR_LOG_ERR.
path_of_log_error_dir() {
    local base
    if [ -n "${DU_BOT_PATH_LOGS_ERROR:-}" ]; then
        ensure_dir "${DU_BOT_PATH_LOGS_ERROR}"
        printf '%s\n' "${DU_BOT_PATH_LOGS_ERROR}"
        return 0
    fi
    base="$(path_of_data_dir)"
    # bashsupport disable=BP2001
    export DU_BOT_PATH_LOGS_ERROR="${base}/${DB_DIR_LOGS:-logs}/${DB_DIR_LOG_ERR:-error}"
    ensure_dir "${DU_BOT_PATH_LOGS_ERROR}"
    printf '%s\n' "${DU_BOT_PATH_LOGS_ERROR}"
}

# Info logging directory: logging directory plus DB_DIR_LOG_INF.
path_of_log_info_dir() {
    local base
    if [ -n "${DU_BOT_PATH_LOGS_INFO:-}" ]; then
        ensure_dir "${DU_BOT_PATH_LOGS_INFO}"
        printf '%s\n' "${DU_BOT_PATH_LOGS_INFO}"
        return 0
    fi
    base="$(path_of_data_dir)"
    # bashsupport disable=BP2001
    export DU_BOT_PATH_LOGS_INFO="${base}/${DB_DIR_LOGS:-logs}/${DB_DIR_LOG_INF:-info}"
    ensure_dir "${DU_BOT_PATH_LOGS_INFO}"
    printf '%s\n' "${DU_BOT_PATH_LOGS_INFO}"
}

path_of_log_error_file() {
    local today log_file_path
    today=$(date +%Y-%m-%d)
    log_file_path="$(path_of_log_error_dir)/${today}.log"
    printf '%s\n' "${log_file_path}"
}

path_of_log_info_file() {
    local today log_file_path
    today=$(date +%Y-%m-%d)
    log_file_path="$(path_of_log_info_dir)/${today}.log"
    printf '%s\n' "${log_file_path}"
}

# Print the configured job limit (0 means no limit). Invalid values are
# treated as no limit, so a bad override cannot break a run.
job_limit() {
    local limit
    limit="${DB_LIMIT_JOBS:-0}"
    case "${limit}" in
    0 | *[!0-9]*) printf '0\n' ;;
    *) printf '%s\n' "${limit}" ;;
    esac
}