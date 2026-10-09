#!/usr/bin/env bash
# Step 1: write the listing-page address table.

PATH_SCR_FN_EXA="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_EXA

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_EXA}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_EXA}/../conf/paths.sh"
source "${PATH_SCR_FN_EXA}/../listing/pagination.sh"
source "${PATH_SCR_FN_EXA}/../http/request.sh"
source "${PATH_SCR_FN_EXA}/../logging/log.sh"

# Write the listing-page address table for the configured start URL.
extract_listing_pages() {
    local out html count
    out="$(path_of_data_item "${DB_DIR_LINKS}/${DB_FILE_LISTING_PAGES}")"
    mkdir -p "$(dirname "${out}")"
    dbot_log "Listing extractor" "Fetching start URL ${DB_START_URL}"
    html="$(fetch_page "${DB_START_URL}")"
    {
        printf 'page\turl\n'
        listing_page_urls "${html}"
    } >"${out}"
    count="$(tail -n +2 "${out}" | wc -l | tr -d ' ')"
    dbot_log "Listing extractor" "${count} addresses stored into ${out}"
    print_step_end "Wrote ${count} urls to ${out}"
}
