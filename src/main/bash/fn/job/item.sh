#!/usr/bin/env bash
# Job-item directories.

# Return the directory path for a job slug.
job_item_dir() {
    local root="${1}"
    local slug="${2}"
    printf '%s/%s\n' "${root}" "${slug}"
}

# Return success when a slug is safe as a directory name.
slug_is_safe() {
    case "${1}" in
    "" | *[/\\]* | .. | .) return 1 ;;
    esac
}
