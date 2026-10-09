#!/usr/bin/env bash
# Downloaded and removed stamp files.

# Write a timestamp into a stamp file.
write_stamp() {
    local file="${1}"
    local stamp="${2}"
    printf '%s\n' "${stamp}" >"${file}"
}

# Add meta-downloaded.txt when an existing job item does not have one.
ensure_downloaded_stamp() {
    local item="${1}"
    local raw="${item}/${DB_FILE_JOB_RAW}"
    local stamp="${item}/${DB_FILE_META_DOWNLOADED}"
    if [ -s "${stamp}" ]; then
        return 1
    fi
    if [ -s "${raw}" ]; then
        write_stamp "${stamp}" "$(file_created_utc "${raw}")"
    else
        write_stamp "${stamp}" "$(utc_now)"
    fi
}

# Add meta-removed.txt when a job item is no longer listed.
ensure_removed_stamp() {
    local item="${1}"
    local when="${2}"
    local stamp="${item}/${DB_FILE_META_REMOVED}"
    if [ -s "${stamp}" ]; then
        return 1
    fi
    write_stamp "${stamp}" "${when}"
}
