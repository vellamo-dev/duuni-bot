#!/usr/bin/env bash
# Download raw job pages and move disappeared listings.

PATH_SCR_FN_ERD="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_ERD

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_ERD}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_ERD}/../conf/paths.sh"
source "${PATH_SCR_FN_ERD}/../job/download.sh"
source "${PATH_SCR_FN_ERD}/../job/removed.sh"
source "${PATH_SCR_FN_ERD}/../logging/log.sh"

# Download listed job pages and move listings that have disappeared.
download_job_raw_data() {
    local in dir listed files
    in="$(path_of_data_item "${DB_DIR_LINKS}/${DB_FILE_JOB_PAGES}")"
    dir="$(path_of_data_items_dir "${DB_DIR_JOBS}")"
    dbot_log "Jobs downloader" "Downloading raw job data from ${in}"
    if [ ! -f "${in}" ]; then
        dbot_error "Jobs downloader" "Missing job-pages table ${in}"
        print_error "Missing ${in}"
        return 1
    fi
    mkdir -p "${dir}"
    listed="$(mktemp)"
    tail -n +2 "${in}" | awk -F'\t' 'NF >= 1 && $1 != "" { print $1 }' >"${listed}"
    download_listed_jobs "${in}" "${dir}"
    mark_removed_jobs "${dir}" "${listed}"
    rm -f "${listed}"
    files="$(find "${dir}" -name "${DB_FILE_JOB_RAW}" | wc -l | tr -d ' ')"
    dbot_log "Jobs downloader" "${files} raw pages stored in ${dir}"
    echo "Files ${files} in ${dir}"
}
