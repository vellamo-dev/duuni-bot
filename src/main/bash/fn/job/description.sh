#!/usr/bin/env bash
# Standalone job HTML pages. Uses DB_TPL_JOB_INFO_HTML from duuni-bot.conf.sh.

PATH_SCR_FN_DSC="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_DSC

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_DSC}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_DSC}/../html/htmlq.sh"
source "${PATH_SCR_FN_DSC}/../logging/log.sh"

# Escape text for an HTML title.
html_text() {
    local text="${1}"
    text="${text//&/&amp;}"
    text="${text//</\&lt;}"
    text="${text//>/\&gt;}"
    printf '%s' "${text}"
}

# Write the job-info template with the title and extracted fragment.
write_html_page() {
    local dest="${1}"
    local title="${2}"
    local body="${3}"
    local tpl tmp line prefix suffix
    tpl="${DB_TPL_JOB_INFO_HTML}"
    case "${tpl}" in
    \~) tpl="${HOME}" ;;
    \~/*) tpl="${HOME}/${tpl#\~/}" ;;
    esac
    case "${tpl}" in
    /*) ;;
    *) tpl="${DUUNI_ROOT}/${tpl#./}" ;;
    esac
    if [ ! -f "${tpl}" ]; then
        dbot_error "Jobs data" "Missing HTML template ${tpl}"
        print_error "Missing ${tpl}"
        return 1
    fi
    tmp="${dest}.part"
    : >"${tmp}"
    while IFS= read -r line || [ -n "${line}" ]; do
        case "${line}" in
        *'<title>'*'</title>'*)
            prefix="${line%%<title>*}"
            suffix="${line#*</title>}"
            line="${prefix}<title>$(html_text "${title}")</title>${suffix}"
            ;;
        esac
        case "${line}" in
        *'<!-- Job Info -->'*)
            printf '%s' "${line%%'<!-- Job Info -->'*}" >>"${tmp}"
            printf '%s' "${body}" >>"${tmp}"
            printf '%s\n' "${line#*'<!-- Job Info -->'}" >>"${tmp}"
            continue
            ;;
        esac
        printf '%s\n' "${line}" >>"${tmp}"
    done <"${tpl}"
    mv "${tmp}" "${dest}"
}

# Write job-data.html from 'div.description-box'.
write_job_data() {
    local raw="${1}"
    local dest="${2}"
    local title="${3}"
    local box
    require_htmlq || return 1
    box="$(htmlq -f "${raw}" 'div.description-box')"
    if [ -z "${box}" ]; then
        dbot_error "Jobs data" "Could not read description-box from ${raw}"
        print_error "Could not read description-box from ${raw}"
        return 1
    fi
    write_html_page "${dest}" "${title}" "${box}"
}

# Write job-description.html from 'div.description--jobentry' only.
write_job_description() {
    local raw="${1}"
    local dest="${2}"
    local title="${3}"
    local box
    require_htmlq || return 1
    box="$(htmlq -f "${raw}" 'div.description--jobentry')"
    if [ -z "${box}" ]; then
        dbot_error "Jobs data" "Could not read description--jobentry from ${raw}"
        print_error "Could not read description--jobentry from ${raw}"
        return 1
    fi
    write_html_page "${dest}" "${title}" "${box}"
}
