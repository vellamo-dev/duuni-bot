#!/usr/bin/env bash
# Shared core for logging functions.

# Print the current time as "YYYY-MM-DD HH:MM:SS,mmm" (millisecond precision).
dbot_timestamp() {
    if command -v perl >/dev/null 2>&1; then
        perl -MTime::HiRes=time -MPOSIX=strftime \
            -e 'printf "%s,%03d", strftime("%Y-%m-%d %H:%M:%S", localtime), int((time-int(time))*1000)' \
            2>/dev/null && return 0
    fi
    date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || true
}

# Escape control characters that would otherwise split a log
# entry across lines so that every entry stays on a single line.
dbot_escape() {
    local s="${1:-}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    printf '%s' "${s}"
}

# Append one sanitised line to a log file.
#
# Arguments: level feature message log_path
#
# - Ensures the parent directory and the file exist.
# - Uses an exclusive lock (flock) when available so concurrent writers cannot
#   interleave lines and fall back to a plain appending otherwise.
# - Falls back to stderr when the log file cannot be written, so a message is
#   never silently dropped.
# - Always returns 0.
dbot_write() {
    local level="${1:-}" feature="${2:-}" message="${3:-}" log_path="${4:-}"
    local ts line dir

    ts="$(dbot_timestamp)"
    feature="$(dbot_escape "${feature}")"
    message="$(dbot_escape "${message}")"
    line="${ts} ${level} [${feature}] ${message}"

    if [ -z "${log_path}" ]; then
        printf '%s\n' "${line}" >&2 || true
        return 0
    fi

    dir="$(dirname "${log_path}" 2>/dev/null || true)"
    if [ -z "${dir}" ] || ! mkdir -p "${dir}" 2>/dev/null; then
        printf '%s\n' "${line}" >&2 || true
        return 0
    fi

    # Append inside a subshell whose stderr is silenced so that a failing
    # redirection cannot leak a raw shell error to the caller; it falls
    # through to the stderr fallback instead.
    if command -v flock >/dev/null 2>&1; then
        (
            exec 9>>"${log_path}" || exit 1
            flock -x 9 2>/dev/null || exit 1
            printf '%s\n' "${line}" >&9 || exit 1
        ) 2>/dev/null || printf '%s\n' "${line}" >&2 || true
    else
        ( printf '%s\n' "${line}" >>"${log_path}" ) 2>/dev/null \
            || printf '%s\n' "${line}" >&2 || true
    fi
    return 0
}

# Terminate after an uncaught error: write the error log, then exit 1.
# Called by the ERR trap installed by dbot_trap_errors.
#
# In a subshell (for example a command substitution) this only aborts the
# subshell; the parent shell's own ERR trap logs the failure, so a single
# terminating entry is written per error.
#
# Arguments (supplied by the trap): line command function
dbot_fail() {
    local rc=$?
    if [ "${BASHPID:-$$}" != "$$" ]; then
        exit 1
    fi
    local context="${DBOT_ERR_CONTEXT:-Script}"
    local line="${1:-?}" cmd="${2:-?}" fn="${3:-}"
    if [ -n "${fn}" ]; then
        dbot_error "${context}" "Terminating after error (code ${rc}) in ${fn} at line ${line}: ${cmd}"
    else
        dbot_error "${context}" "Terminating after error (code ${rc}) at line ${line}: ${cmd}"
    fi
    exit 1
}

# Install an ERR trap so an unexpected error is logged and the script exits 1.
# `set -E` (errtrace) makes the trap also catch failures inside functions,
# which is where most of this code base reports its errors.
#
# Usage (once, in a top-level script, after sourcing log.sh):
#     dbot_trap_errors "Main"
dbot_trap_errors() {
    DBOT_ERR_CONTEXT="${1:-Script}"
    set -E
    trap 'dbot_fail "$LINENO" "$BASH_COMMAND" "${FUNCNAME[0]:-}"' ERR
}
