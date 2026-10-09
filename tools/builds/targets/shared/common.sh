# Shared helpers for all target scripts (macOS and Linux).
# Colours and print helpers. Target-specific helpers live in each target's
# shared/common.sh, which sources this file.

# Terminal colours.
RED=$'\033[31m'
YELLOW=$'\033[33m'
GREEN=$'\033[32m'
RESET=$'\033[0m'

# Print helpers.
info()  { printf '%s\n' "$*"; }
warn()  { printf '%s%s%s\n' "${YELLOW}" "$*" "${RESET}"; }
error() { printf '%s%s%s\n' "${RED}" "$*" "${RESET}" >&2; }
ok()    { printf '%s%s%s\n' "${GREEN}" "$*" "${RESET}"; }
