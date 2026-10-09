#!/usr/bin/env bash
# Validate a Duuni-Bot data directory (local or container output).
#
# Usage: check-extracted-data.sh [data-dir]
#   data-dir defaults to $DB_ENV_PATH_DATA. Fails when neither is available.
#
# Read-only: it only inspects the directory and never modifies it.

set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR

# Expected file/directory names come from the application configuration, so
# this validator stays in sync with the pipeline.
source "${SCRIPT_DIR}/../../src/main/bash/duuni-bot.conf.sh"

# Terminal colours.
RED=$'\033[31m'
YELLOW=$'\033[33m'
GREEN=$'\033[32m'
RESET=$'\033[0m'

info()  { printf '%s\n' "$*"; }
warn()  { printf '%s%s%s\n' "${YELLOW}" "$*" "${RESET}"; }
error() { printf '%s%s%s\n' "${RED}" "$*" "${RESET}" >&2; }
ok()    { printf '%s%s%s\n' "${GREEN}" "$*" "${RESET}"; }

# Print usage to stderr.
usage() {
    cat >&2 <<EOF
Usage: $(basename "$0") [data-dir]
Validates a Duuni-Bot data directory (local or container output).
data-dir defaults to \$DB_ENV_PATH_DATA.
EOF
}

# Resolve the data directory from the argument or DB_ENV_PATH_DATA.
resolve_data_dir() {
    local dir="${1:-}"
    if [ -z "${dir}" ]; then
        dir="${DB_ENV_PATH_DATA:-}"
    fi
    if [ -z "${dir}" ]; then
        error "No data directory: pass one as an argument or set DB_ENV_PATH_DATA."
        return 1
    fi
    if [ ! -d "${dir}" ]; then
        error "Not a directory: ${dir}"
        return 1
    fi
    printf '%s\n' "${dir}"
}

# Run the validation. Returns 0 when the data looks valid, 1 otherwise.
main() {
    local data jobs links job meta desc total problems
    local job_problem

    case "${1:-}" in
    -h | --help) usage; exit 0 ;;
    esac

    if ! data="$(resolve_data_dir "${1:-}")"; then
        usage
        exit 1
    fi

    info "Checking data directory: ${data}"

    # Top-level structure.
    for d in "${DB_DIR_JOBS}" "${DB_DIR_LINKS}"; do
        if [ ! -d "${data}/${d}" ]; then
            error "Missing directory: ${d}/"
            return 1
        fi
    done

    jobs="${data}/${DB_DIR_JOBS}"
    links="${data}/${DB_DIR_LINKS}"

    # Link tables must exist and be non-empty.
    for f in "${DB_FILE_LISTING_PAGES}" "${DB_FILE_JOB_PAGES}"; do
        if [ ! -s "${links}/${f}" ]; then
            error "Missing or empty link table: ${DB_DIR_LINKS}/${f}"
            return 1
        fi
    done

    # Per-job checks.
    total=0
    problems=0
    for job in "${jobs}"/*; do
        [ -d "${job}" ] || continue
        total=$((total + 1))
        job_problem=0

        meta="${job}/${DB_FILE_META_JSON}"
        if [ ! -s "${meta}" ]; then
            error "  $(basename "${job}"): missing ${DB_FILE_META_JSON}"
            job_problem=1
        elif command -v jq >/dev/null 2>&1 && ! jq -e . "${meta}" >/dev/null 2>&1; then
            error "  $(basename "${job}"): invalid JSON in ${DB_FILE_META_JSON}"
            job_problem=1
        fi

        desc="${job}/${DB_FILE_JOB_DESCRIPTION_TXT}"
        if [ ! -s "${desc}" ]; then
            error "  $(basename "${job}"): missing or empty ${DB_FILE_JOB_DESCRIPTION_TXT}"
            job_problem=1
        fi

        if [ ! -s "${job}/${DB_FILE_JOB_RAW}" ]; then
            warn "  $(basename "${job}"): no ${DB_FILE_JOB_RAW}"
        fi

        if [ "${job_problem}" -eq 1 ]; then
            problems=$((problems + 1))
        fi
    done

    if [ "${total}" -eq 0 ]; then
        error "No job directories found under ${DB_DIR_JOBS}/."
        return 1
    fi

    echo
    if [ "${problems}" -eq 0 ]; then
        ok "Checked ${total} jobs: all present and valid."
        return 0
    else
        error "Checked ${total} jobs: ${problems} with problems."
        return 1
    fi
}

main "${@}"
