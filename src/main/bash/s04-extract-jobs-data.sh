#!/usr/bin/env bash
# Step 4 - s04-extract-jobs-data.sh
# Read each jobs/<slug>/raw.html whose meta.json lacks the slug fields.
# Write meta.json, job-data.html, job-description.html, and job-description.txt.
set -u
set -E

PATH_SCR_S04="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_S04

if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_S04}/duuni-bot.conf.sh"
fi

source "${PATH_SCR_S04}/fn/job/extract_data.sh"
source "${PATH_SCR_S04}/fn/clean/clean_extracted_data.sh"
source "${PATH_SCR_S04}/fn/logging/log.sh"

dbot_trap_errors "Jobs data"
dbot_log "Jobs data" "Starting job data extraction"

# Clean previously extracted data when --clean-first is passed
for arg in "$@"; do
    case "${arg}" in
    --clean-first)
        dbot_log "Jobs data" "Clean-first requested"
        clean_extracted_data
        ;;
    esac
done

# Run data extraction
extract_jobs_data

dbot_log "Jobs data" "Job data extraction completed"
