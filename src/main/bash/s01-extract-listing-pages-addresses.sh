#!/usr/bin/env bash
# Step 1 - s01-extract-listing-pages-addresses.sh
# List every Duunitori listing page for the configured segment.
# Page count and the page-2 URL come from div.pagination__splitted.
set -euo pipefail
set -E

PATH_SCR_S02="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_S02

if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_S02}/duuni-bot.conf.sh"
fi

source "${PATH_SCR_S02}/fn/listing/extract_pages.sh"
source "${PATH_SCR_S02}/fn/clean/reset_data.sh"
source "${PATH_SCR_S02}/fn/logging/log.sh"

dbot_trap_errors "Listing extractor"
dbot_log "Listing extractor" "Starting listing page extraction"

# Clean previously extracted data when --reset-data is passed
for arg in "$@"; do
    case "${arg}" in
    --reset-data)
        dbot_log "Listing extractor" "Full data reset requested"
        reset_all_data
        ;;
    esac
done

extract_listing_pages

dbot_log "Listing extractor" "Listing page extraction completed"
