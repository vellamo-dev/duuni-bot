#!/usr/bin/env bash
# Step 5 - s05-detect-language.sh
# Detect language of job offering.
set -u
set -E

PATH_SCR_S05="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_S05

# Dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_S05}/duuni-bot.conf.sh"
fi
source "${PATH_SCR_S05}/fn/job/lang_detector.sh"
source "${PATH_SCR_S05}/fn/logging/log.sh"

dbot_trap_errors "Language"
dbot_log "Language" "Starting language detection"

detect_jobs_language

dbot_log "Language" "Language detection completed"