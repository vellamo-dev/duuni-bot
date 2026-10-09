#!/usr/bin/env bash
# Step 2 - s02-extract-job-pages-addresses.sh
# Clear lists/, save each listing page as lists/<id>.html, then extract cards from those files.
# Extraction is local, so a repeated parse of the same snapshot does not change the result.
set -euo pipefail
set -E

PATH_SCR_S02="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_S02

if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_S02}/duuni-bot.conf.sh"
fi
source "${PATH_SCR_S02}/fn/listing/extract_jobs.sh"

dbot_trap_errors "Jobs extractor"
dbot_log "Jobs extractor" "Starting job page extraction"

extract_job_pages

dbot_log "Jobs extractor" "Job page extraction completed"
