#!/usr/bin/env bash
# Executes all steps in order.

set -euo pipefail
set -E

PATH_SCR_BOT="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_BOT

# Dependencies
source "${PATH_SCR_BOT}/duuni-bot.conf.sh"
source "${PATH_SCR_BOT}/fn/logging/log.sh"
source "${PATH_SCR_BOT}/fn/clean/reset_data.sh"
source "${PATH_SCR_BOT}/fn/clean/clean_logs.sh"
source "${PATH_SCR_BOT}/fn/clean/purge_data.sh"
source "${PATH_SCR_BOT}/fn/meta/time.sh"

dbot_trap_errors "Duuni Bot"
cleanup_old_logs
mark_removed_for_purge
purge_marked_data
dbot_log "Duuni Bot" "Starting Duuni Bot run"
print_step_start "Starting Duuni Bot run"
start="$(epoch_now)"

# Report whether the optional step 7 runs in this invocation.
if [ "${DB_ENABLE_ST_EK2:-0}" = "1" ]; then
    dbot_log "Duuni Bot" "Step 7 (extended keywords) is enabled"
    echo "Step 7 (extended keywords) is enabled"
else
    dbot_log "Duuni Bot" "Step 7 (extended keywords) is disabled - it will be skipped"
    print_step_start "Step 7 (extended keywords) is disabled - it will be skipped"
fi

# Reset all data (keeping logs) when --reset-all-data is passed.
for arg in "$@"; do
    case "${arg}" in
    --reset-all-data)
        dbot_log "Duuni Bot" "Data reset requested (logs preserved)"
        reset_data_except_logs
        ;;
    esac
done

# Run every configured step in order from 1 to N.
run_all_steps() {
    local i script
    for (( i = 1; i < ${#DB_RS[@]}; i++ )); do
        script="${DB_RS[${i}]}"
        if [ "${i}" -eq 7 ] && [ "${DB_ENABLE_ST_EK2:-0}" != "1" ]; then
            dbot_log "Duuni Bot" "Skipping step ${i} (${script}) - disabled by DB_ENABLE_ST_EK2"
            print_step_start "Skipping step ${i}: ${script} (disabled)"
            continue
        fi
        if [ -z "${script}" ] || [ ! -f "${PATH_SCR_BOT}/${script}" ]; then
            dbot_error "Duuni Bot" "Missing step script for step ${i}"
            return 1
        fi
        dbot_log "Duuni Bot" "Running step ${i}: ${script}"
        print_step_start "Running step ${i}: ${script}"
        if ! bash "${PATH_SCR_BOT}/${script}"; then
            dbot_error "Duuni Bot" "Step ${i} (${script}) failed"
            print_error "Step ${i} (${script}) failed"
            return 1
        fi
    done
}

run_all_steps

elapsed=$(( $(epoch_now) - start ))
dbot_log "Duuni Bot" "Duuni-bot run completed in $(format_duration "${elapsed}")"
print_step_end "Duuni-bot run completed in $(format_duration "${elapsed}")"
