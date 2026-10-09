#!/usr/bin/env bash

PATH_SCR_FN_RSD="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_RSD

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_RSD}/../../duuni-bot.conf.sh"
fi

source "${PATH_SCR_FN_RSD}/../conf/paths.sh"
source "${PATH_SCR_FN_RSD}/../logging/log.sh"

reset_all_data() {
    local path_dir_data count1 count2
    path_dir_data="$(path_of_data_dir)"
    echo "Resetting all data: ${path_dir_data}"
    if [ ! -d "${path_dir_data}" ]; then
        print_error "Missing ${path_dir_data}"
        dbot_error "Data reset" "Missing data directory ${path_dir_data}"
        return 1
    fi
    count1=$(find "${path_dir_data}" -mindepth 1 | wc -l)
    echo "Removing ${count1} data items..."
    find "${path_dir_data}" -mindepth 1 -delete
    count2=$(find "${path_dir_data}" -mindepth 1 | wc -l)
    if [ "${count2}" -eq 0 ]; then
        dbot_log "Data reset" "All data removed"
        echo "All data removed"
    else
        dbot_error "Data reset" "Some data remained (${count2})"
        print_error "Some data remained (${count2})."
    fi
}

# Reset all data but keep the logs directory intact.
reset_data_except_logs() {
    local path_dir_data logs_root count1 count2
    path_dir_data="$(path_of_data_dir)"
    logs_root="${path_dir_data}/${DB_DIR_LOGS:-logs}"
    echo "Resetting all data (logs preserved): ${path_dir_data}"
    if [ ! -d "${path_dir_data}" ]; then
        print_error "Missing ${path_dir_data}"
        dbot_error "Data reset" "Missing data directory ${path_dir_data}"
        return 1
    fi
    count1=$(find "${path_dir_data}" -mindepth 1 \
        -not -path "${logs_root}" -not -path "${logs_root}/*" | wc -l)
    echo "Removing ${count1} data items (logs preserved)..."
    find "${path_dir_data}" -mindepth 1 \
        -not -path "${logs_root}" -not -path "${logs_root}/*" -delete
    count2=$(find "${path_dir_data}" -mindepth 1 \
        -not -path "${logs_root}" -not -path "${logs_root}/*" | wc -l)
    if [ "${count2}" -eq 0 ]; then
        dbot_log "Data reset" "All data removed (logs preserved)"
        echo "All data removed"
    else
        dbot_error "Data reset" "Some data remained (${count2})"
        print_error "Some data remained (${count2})."
    fi
}