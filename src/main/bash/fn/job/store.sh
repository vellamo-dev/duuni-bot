#!/usr/bin/env bash
# Move job items between the active and removed directories.

PATH_SCR_FN_STR="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_DNL

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_STR}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_STR}/../conf/paths.sh"

# Move a legacy slug.html file into the item directory.
adopt_legacy_html() {
    local item="${1}"
    local old="${2}"
    local out="${item}/${DB_FILE_JOB_RAW}"
    if [ ! -s "${out}" ] && [ -s "${old}" ]; then
        mv "${old}" "${out}"
    fi
}

# Move a slug back from the removed directory when it is listed again.
restore_listed_job() {
    local active="${1}"
    local slug="${2}"
    local removed_root item
    removed_root="$(path_of_data_items_dir "${DB_DIR_JOBS_REMOVED}")"
    item="${removed_root}/${slug}"
    if [ -d "${active}" ] || [ ! -d "${item}" ]; then
        return 0
    fi
    mkdir -p "$(dirname "${active}")"
    mv "${item}" "${active}"
    rm -f "${active}/${DB_FILE_META_REMOVED}"
}
