#!/usr/bin/env bash

PATH_SCR_FN_CED="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_CED

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_CED}/../../duuni-bot.conf.sh"
fi

source "${PATH_SCR_FN_CED}/../conf/paths.sh"
source "${PATH_SCR_FN_CED}/../logging/log.sh"

clean_extracted_data() {
    local path_jobs_dir count
    path_jobs_dir="$(path_of_data_items_dir "${DB_DIR_JOBS}")"
    dbot_log "Jobs data" "Cleaning extracted job data in ${path_jobs_dir}"
    echo "Cleaning extracted jobs data in: ${path_jobs_dir}"
    if [ ! -d "${path_jobs_dir}" ]; then
        dbot_error "Jobs data" "Missing jobs directory ${path_jobs_dir}"
        print_error "Missing ${path_jobs_dir}"
        return 1
    fi
    count="$(
        find "${path_jobs_dir}" -mindepth 2 -maxdepth 2 -type f \( \
            -name "${DB_FILE_META_JSON}" -o \
            -name "${DB_FILE_JOB_DATA}" -o \
            -name "${DB_FILE_JOB_DESCRIPTION}" -o \
            -name "${DB_FILE_JOB_KEYWORDS_V1}" -o \
            -name "${DB_FILE_JOB_KEYWORDS_V1_CAT}" -o \
            -name "${DB_FILE_JOB_KEYWORDS_V2}" -o \
            -name "${DB_FILE_JOB_KEYWORDS_V2_CAT}" -o \
            -name "${DB_FILE_JOB_DESCRIPTION_TXT}" \
            \) -print -exec rm -f -- {} + | wc -l | tr -d ' '
    )"
    dbot_log "Jobs data" "Removed ${count} extracted items"
    echo "Removed ${count} items."
}