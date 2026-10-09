#!/usr/bin/env bash
# ./tools/clean-job-extractions.sh
# Clean extracted data
set -u

PATH_SCR_SC_CED="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_SC_CED

# Load dependencies
source "${PATH_SCR_SC_CED}/../src/main/bash/fn/clean/clean_extracted_data.sh"

clean_extracted_data