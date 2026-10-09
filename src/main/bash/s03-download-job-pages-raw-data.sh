#!/usr/bin/env bash
# Step 3 - s03-download-job-pages-raw-data.sh
# Download each job URL into <data>/<jobs>/<slug>/<raw>.html.
# Already saved pages are skipped. A failed request does not stop the run.
# Missing meta-downloaded.txt is added. Items absent from the listing are marked and moved to jobs-removed/.
set -u
set -E

PATH_SCR_S03="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_S03

if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_S03}/duuni-bot.conf.sh"
fi

source "${PATH_SCR_S03}/fn/job/extract_raw.sh"
source "${PATH_SCR_S03}/fn/clean/clean_extracted_jobs.sh"
source "${PATH_SCR_S03}/fn/logging/log.sh"

dbot_trap_errors "Jobs downloader"
dbot_log "Jobs downloader" "Starting raw job data download"

# Clean previously extracted data when --clean-first is passed
for arg in "$@"; do
    case "${arg}" in
    --clean-first)
        dbot_log "Jobs downloader" "Clean-first requested"
        clean_extracted_jobs
        ;;
    esac
done

download_job_raw_data

dbot_log "Jobs downloader" "Raw job data download completed"
