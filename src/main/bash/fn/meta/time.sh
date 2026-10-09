#!/usr/bin/env bash
# UTC timestamp conversions.

# Print the current time as a UTC timestamp.
utc_now() {
    date -u +%Y-%m-%dT%H:%M:%SZ
}

# Convert a Unix epoch to a UTC timestamp.
epoch_to_utc() {
    local epoch="${1}"
    if date -u -r "${epoch}" +%Y-%m-%dT%H:%M:%SZ >/dev/null 2>&1; then
        date -u -r "${epoch}" +%Y-%m-%dT%H:%M:%SZ
    else
        date -u -d "@${epoch}" +%Y-%m-%dT%H:%M:%SZ
    fi
}

# Print a file birth time as a UTC timestamp.
file_created_utc() {
    local file="${1}"
    local epoch=""
    if epoch="$(stat -f %B "${file}" 2>/dev/null)" && [ -n "${epoch}" ] && [ "${epoch}" != "0" ]; then
        epoch_to_utc "${epoch}"
        return
    fi
    epoch="$(stat -c %W "${file}" 2>/dev/null || true)"
    if [ -z "${epoch}" ] || [ "${epoch}" = "0" ]; then
        epoch="$(stat -c %Y "${file}")"
    fi
    epoch_to_utc "${epoch}"
}

# Print the current Unix epoch time in whole seconds.
epoch_now() {
    date +%s 2>/dev/null || perl -e 'print int(time)' 2>/dev/null || true
}

# Print a duration in whole seconds as "Xm Ys" (always minutes and seconds).
format_duration() {
    local total="${1:-0}" m
    case "${total}" in
    '' | *[!0-9]*) total=0 ;;
    esac
    m=$((total / 60))
    printf '%dm %ds' "${m}" "$((total % 60))"
}
