#!/usr/bin/env bash
# Embeds both logging functions: info and error.

if [ -z "${PATH_SCR_FN_LOG:-}" ]; then
    PATH_SCR_FN_LOG="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly PATH_SCR_FN_LOG
fi

# Load dependencies
source "${PATH_SCR_FN_LOG}/log_info.sh"
source "${PATH_SCR_FN_LOG}/log_error.sh"
source "${PATH_SCR_FN_LOG}/../progress/report.sh"
