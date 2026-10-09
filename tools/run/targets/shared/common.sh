# Shared helpers for the run scripts (macOS and Linux).

RED=$'\033[31m'
YELLOW=$'\033[33m'
GREEN=$'\033[32m'
RESET=$'\033[0m'

info()  { printf '%s\n' "$*"; }
warn()  { printf '%s%s%s\n' "${YELLOW}" "$*" "${RESET}"; }
error() { printf '%s%s%s\n' "${RED}" "$*" "${RESET}" >&2; }
ok()    { printf '%s%s%s\n' "${GREEN}" "$*" "${RESET}"; }
