#!/usr/bin/env bash
# Runs a configured step. Steps are the DB_RS array in duuni-bot.conf.sh.
set -euo pipefail
set -E

PATH_SCR_RUN="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_RUN

if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_RUN}/duuni-bot.conf.sh"
fi
source "${PATH_SCR_RUN}/fn/logging/log.sh"
source "${PATH_SCR_RUN}/fn/clean/reset_data.sh"

dbot_trap_errors "Main"

# Print the configured step numbers.
bot_steps_available() {
    local i
    for (( i = 1; i < ${#DB_RS[@]}; i++ )); do
        printf '%s\n' "${i}"
    done
}

# Print the script path configured for a step.
bot_step_file() {
    printf '%s\n' "${DB_RS[${1}]-}"
}

# Print usage and the configured steps.
print_bot_instructions() {
    local n file
    echo "Usage: bash run.sh -s <step> [args...]"
    echo
    echo "Steps:"
    for n in $(bot_steps_available); do
        file="$(bot_step_file "${n}")"
        printf '  %s  %s\n' "${n}" "${file}"
    done
}

# Print an error and usage, then exit.
fail_usage() {
    print_error "${1}"
    dbot_error "Main" "Failed to determine the task - ${1}"
    print_bot_instructions >&2
    exit 1
}

# Parse the step argument from the command line.
parse_step() {
    STEP=""
    STEP_ARGS=()
    RESET_DATA=0
    if [ ${#} -eq 0 ]; then
        print_bot_instructions
        exit 0
    fi
    while [ ${#} -gt 0 ]; do
        case "${1}" in
        -s)
            if [ ${#} -lt 2 ] || [ -z "${2}" ]; then
                fail_usage "Missing step"
            fi
            STEP="${2}"
            shift 2
            ;;
        -h | --help)
            print_bot_instructions
            exit 0
            ;;
        --reset-data)
            RESET_DATA=1
            shift
            ;;
        *)
            STEP_ARGS+=("${1}")
            shift
            ;;
        esac
    done
    if [ -z "${STEP}" ]; then
        fail_usage "Missing step"
    fi
}

# Return success when the argument is a non-empty number.
step_is_number() {
    case "${1}" in
    '' | *[!0-9]*) return 1 ;;
    esac
}

# Resolve a step number to an existing script path.
resolve_step_script() {
    local step="${1}"
    local file
    step_is_number "${step}" || return 1
    file="$(bot_step_file "${step}")"
    if [ -z "${file}" ] || [ ! -f "${PATH_SCR_RUN}/${file}" ]; then
        return 1
    fi
    printf '%s\n' "${PATH_SCR_RUN}/${file}"
}

# Replace this process with the step script, forwarding remaining arguments.
run_step() {
    local script="${1}"
    dbot_log "Main" "Starting handling of request: ${STEP} -> $(basename "${script}")"
    shift
    exec bash "${script}" "${@}"
}

# Parse arguments and run the selected step.
main() {
    local script
    parse_step "${@}"
    script="$(resolve_step_script "${STEP}")" || fail_usage "Unknown step: ${STEP}"
    # A full reset is a step-1-only feature. Do it before any logging so this
    # run's own log entries are written on a clean slate and survive.
    if [ "${RESET_DATA}" -eq 1 ]; then
        if [ "${STEP}" != "1" ]; then
            print_error "--reset-data is only available for step 1"
            dbot_error "Main" "--reset-data is only available for step 1"
            exit 1
        fi
        reset_all_data
    fi
    dbot_log "Main" "Determining user request"
    if [ ${#STEP_ARGS[@]} -gt 0 ]; then
        run_step "${script}" "${STEP_ARGS[@]}"
    else
        run_step "${script}"
    fi
}

main "${@}"
