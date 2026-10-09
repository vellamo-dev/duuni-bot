#!/usr/bin/env bash
# Listing pagination. Uses htmlq.

PATH_SCR_FN_LPU="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_LPU

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_LPU}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_LPU}/../html/htmlq.sh"
source "${PATH_SCR_FN_LPU}/../logging/log.sh"

# Extract numbered listing-page URLs from pagination HTML.
listing_page_urls() {
    local tmp hrefs last page base url
    require_htmlq || return 1
    tmp="$(mktemp)"
    printf '%s\n' "${1}" >"${tmp}"
    hrefs="$(htmlq -f "${tmp}" -a href 'div.pagination__splitted a.pagination__pagenum')"
    rm -f "${tmp}"
    last="$(printf '%s\n' "${hrefs}" | sed -n 's/.*[?&]sivu=\([0-9][0-9]*\).*/\1/p' | sort -n | tail -n 1)"
    base="$(printf '%s\n' "${hrefs}" | head -n 1)"
    base="${base%%\?*}"
    if [ -z "${hrefs}" ] || [ -z "${last}" ] || [ -z "${base}" ]; then
        print_error "Could not read pagination__splitted"
        dbot_error "Listing extractor" "Failed to read pages pagination"
        return 1
    fi
    echo "Pages	${last}" >&2
    dbot_log "Listing extractor" "${last} listing pages detected"
    page=1
    while [ "${page}" -le "${last}" ]; do
        if [ "${page}" -eq 1 ]; then
            url="${base}"
        else
            url="${base}?sivu=${page}"
        fi
        printf '%s\t%s\n' "${page}" "${url}"
        page=$((page + 1))
    done
}
