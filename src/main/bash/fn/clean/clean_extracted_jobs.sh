#!/usr/bin/env bash

PATH_SCR_FN_CJD="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_CJD

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_CJD}/../../duuni-bot.conf.sh"
fi

source "${PATH_SCR_FN_CJD}/../conf/paths.sh"
source "${PATH_SCR_FN_CJD}/../logging/log.sh"

clean_extracted_jobs() {
    local path_jobs_dir count1 count2
    path_jobs_dir="$(path_of_data_items_dir "${DB_DIR_JOBS}")"
    dbot_log "Jobs clean" "Cleaning extracted jobs in ${path_jobs_dir}"
    echo "Cleaning extracted jobs in: ${path_jobs_dir}"
    if [ ! -d "${path_jobs_dir}" ]; then
        dbot_error "Jobs clean" "Missing jobs directory ${path_jobs_dir}"
        print_error "Missing directory: ${path_jobs_dir}"
        return 1
    fi
    count1=$(find "${path_jobs_dir}" -mindepth 1 | wc -l)
    echo "Removing ${count1} job items..."
    find "${path_jobs_dir}" -mindepth 1 -delete
    count2=$(find "${path_jobs_dir}" -mindepth 1 | wc -l)
    if [ "${count2}" -eq 0 ]; then
        dbot_log "Jobs clean" "All items removed"
        echo "All items removed"
    else
        echo "Some items remained (${count2})."
    fi
}