#!/usr/bin/env bash
# Mark job directories that have left the listing and move them aside.

PATH_SCR_FN_MRJ="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_MRJ

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_MRJ}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_MRJ}/../conf/paths.sh"
source "${PATH_SCR_FN_MRJ}/../meta/stamp.sh"
source "${PATH_SCR_FN_MRJ}/../logging/log.sh"

# Mark and move job directories that are no longer in the listing.
mark_removed_jobs() {
    local dir="${1}"
    local listed="${2}"
    local removed_root item slug scan removed stamped
    removed_root="$(path_of_data_items_dir "${DB_DIR_JOBS_REMOVED}")"
    mkdir -p "${removed_root}"
    scan="$(utc_now)"
    removed=0
    stamped=0
    dbot_log "Jobs downloader" "Marking removed jobs in ${dir}"
    for item in "${dir}"/*; do
        [ -d "${item}" ] || continue
        slug="$(basename "${item}")"
        if grep -F -x -q -- "${slug}" "${listed}"; then
            if [ -s "${item}/${DB_FILE_JOB_RAW}" ] && ensure_downloaded_stamp "${item}"; then
                stamped=$((stamped + 1))
            fi
            continue
        fi
        ensure_removed_stamp "${item}" "${scan}" || true
        if ensure_downloaded_stamp "${item}"; then
            stamped=$((stamped + 1))
        fi
        if [ -e "${removed_root}/${slug}" ]; then
            rm -rf "${removed_root}/${slug}"
        fi
        mv "${item}" "${removed_root}/${slug}"
        removed=$((removed + 1))
    done
    dbot_log "Jobs downloader" "stamped ${stamped}, removed ${removed}"
    echo "Stamped ${stamped}"
    echo "Removed ${removed}"
}
