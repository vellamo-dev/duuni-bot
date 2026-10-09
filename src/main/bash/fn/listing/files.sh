#!/usr/bin/env bash
# Saved listing-page files.

# Print saved listing files in page-number order.
listing_files() {
    local dir="${1}"
    local file base
    find "${dir}" -type f -name '*.html' -print | while IFS= read -r file; do
        base="$(basename "${file}" .html)"
        case "${base}" in
        "" | *[!0-9]*) continue ;;
        esac
        printf '%s\t%s\n' "${base}" "${file}"
    done | sort -n | cut -f2-
}

# Remove and recreate the saved listing-page directory.
reset_listing_dir() {
    local lists="${1}"
    rm -rf "${lists}"
    mkdir -p "${lists}"
}
