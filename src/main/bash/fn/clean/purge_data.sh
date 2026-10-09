#!/usr/bin/env bash
# Purge data marked with a .purge marker.

PATH_SCR_FN_PRG="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_PRG

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_PRG}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_PRG}/../conf/paths.sh"

# Write a .purge marker into a directory.
mark_for_purge() {
    local dir="${1}"
    [ -n "${dir}" ] && [ -d "${dir}" ] || return 0
    touch "${dir}/${DB_MARK_PURGE}" 2>/dev/null || true
    return 0
}

# Mark removed-job directories for purge once they exceed the retention days.
# An external processor can also place a .purge marker itself, and the next
# run deletes it. This is only the bot's own automatic way of marking.
mark_removed_for_purge() {
    local dir days item
    dir="$(path_of_data_items_dir "${DB_DIR_JOBS_REMOVED}" 2>/dev/null || true)"
    [ -n "${dir}" ] || return 0
    days="${DB_REMOVED_RETENTION_DAYS:-30}"
    case "${days}" in
    '' | *[!0-9]*) days=30 ;;
    esac
    [ "${days}" -gt 0 ] || return 0
    for item in "${dir}"/*; do
        [ -d "${item}" ] || continue
        if find "${item}" -maxdepth 0 -type d -mtime +"${days}" 2>/dev/null | grep -q .; then
            mark_for_purge "${item}"
        fi
    done
    return 0
}

# Delete every job directory (jobs/ and jobs-removed/) carrying a .purge marker.
purge_marked_data() {
    local base dir item
    for base in "${DB_DIR_JOBS}" "${DB_DIR_JOBS_REMOVED}"; do
        dir="$(path_of_data_items_dir "${base}" 2>/dev/null || true)"
        [ -n "${dir}" ] || continue
        for item in "${dir}"/*; do
            [ -d "${item}" ] || continue
            if [ -e "${item}/${DB_MARK_PURGE}" ]; then
                rm -rf "${item}" 2>/dev/null || true
            fi
        done
    done
    return 0
}
