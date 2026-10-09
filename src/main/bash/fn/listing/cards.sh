#!/usr/bin/env bash
# Search-result cards. Uses htmlq.

PATH_SCR_FN_CRD="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_CRD

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_CRD}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_CRD}/../html/htmlq.sh"

# Print slug, url, and title for each search-result card.
extract_job_cards() {
    local src hrefs slugs titles slug url title
    require_htmlq || return 1
    src="$(mktemp)"
    hrefs="$(mktemp)"
    slugs="$(mktemp)"
    titles="$(mktemp)"
    cat >"${src}"
    htmlq -f "${src}" -a href 'a.job-box__hover.gtm-search-result' >"${hrefs}"
    htmlq -f "${src}" -a data-job-slug 'a.job-box__hover.gtm-search-result' >"${slugs}"
    htmlq -f "${src}" -w -t 'a.job-box__hover.gtm-search-result' | sed '/^[[:space:]]*$/d' >"${titles}"
    rm -f "${src}"
    paste "${slugs}" "${hrefs}" "${titles}" | while IFS="$(printf '\t')" read -r slug url title; do
        [ -n "${slug}" ] && [ -n "${url}" ] && [ -n "${title}" ] || continue
        case "${url}" in
        /*) url="${DB_ORIGIN}${url}" ;;
        esac
        slug="$(printf '%s' "${slug}" | tr -cd 'A-Za-z0-9._-')"
        title="$(printf '%s' "${title}" | tr '\n' ' ' | sed 's/[[:space:]]\{1,\}/ /g;s/^ //;s/ $//')"
        printf '%s\t%s\t%s\n' "${slug}" "${url}" "${title}"
    done
    rm -f "${hrefs}" "${slugs}" "${titles}"
}
