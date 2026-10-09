#!/usr/bin/env bash
# Terminal colours, step banners and padded progress lines.
# Uses DB_MARK_SKIP and DB_MARK_FAIL.

# Terminal colours.
COL_RESET=$'\033[0m'
COL_GREEN=$'\033[32m'
COL_YELLOW=$'\033[33m'
COL_RED=$'\033[31m'

# Print a step-start banner in yellow.
print_step_start() {
    printf "${COL_YELLOW}%s${COL_RESET}\n" "$1"
}

# Print a successful step summary in green.
print_step_end() {
    printf "${COL_GREEN}%s${COL_RESET}\n" "$1"
}

# Print an error message in red to stderr.
print_error() {
    printf "${COL_RED}%s${COL_RESET}\n" "$1" >&2
}

# Return the digit width of a total count.
progress_width() {
    local total="${1}"
    printf '%s\n' "${#total}"
}

# Print a padded progress line, with an optional coloured mark.
print_progress() {
    local width="${1}"
    local n="${2}"
    local title="${3}"
    local mark="${4:-}"
    case "${mark}" in
    skip)
        printf "%*s %s ${COL_YELLOW}[%s]${COL_RESET}\n" "${width}" "${n}" "${title}" "${mark}"
        ;;
    fail)
        printf "%*s %s ${COL_RED}[%s]${COL_RESET}\n" "${width}" "${n}" "${title}" "${mark}" >&2
        ;;
    '')
        printf "%*s %s\n" "${width}" "${n}" "${title}"
        ;;
    *)
        printf "%*s %s [%s]\n" "${width}" "${n}" "${title}" "${mark}"
        ;;
    esac
}
