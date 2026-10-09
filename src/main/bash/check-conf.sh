#!/usr/bin/env bash
# Checks the configuration values and prints these
# bash check-conf.sh

set -u

SCRIPT_DIR="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

YELLOW=$'\033[33m'
GREEN=$'\033[32m'
RED=$'\033[31m'
RESET=$'\033[0m'

# Load the configuration. This also applies any DB_ENV_* overrides, so the
# effective values are shown below.
source "${SCRIPT_DIR}/duuni-bot.conf.sh"

# Print a configured value: yellow name, green value.
print_set() {
    printf '  %s%s%s = %s%s%s\n' "${YELLOW}" "$1" "${RESET}" "${GREEN}" "$2" "${RESET}"
}

# Print an unset value: yellow name, red [not set].
print_unset() {
    printf '  %s%s%s = %s[not set]%s\n' "${YELLOW}" "$1" "${RESET}" "${RED}" "${RESET}"
}

echo
echo "Configuration (duuni-bot.conf.sh)"
echo "================================="

# All variables defined by the configuration start with DB_.
for var in $(compgen -v 'DB_' | sort); do
    # Environment overrides are printed separately below.
    case "${var}" in
    DB_ENV_*) continue ;;
    esac

    if declare -p "${var}" 2>/dev/null | grep -q '^declare -a'; then
        # Arrays are printed as their non-empty elements joined by a space.
        declare -n ref="${var}"
        parts=""
        for e in "${ref[@]}"; do
            [ -n "${e}" ] || continue
            parts="${parts}${parts:+ }${e}"
        done
        print_set "${var}" "${parts}"
    else
        print_set "${var}" "${!var}"
    fi
done

echo
echo "Environment overrides"
echo "====================="
echo "(environment variables - must be exported to appear here)"

# The override variable names are read from the configuration itself.
for var in $(grep -oE 'DB_ENV_[A-Z0-9_]+' "${SCRIPT_DIR}/duuni-bot.conf.sh" | sort -u); do
    value="${!var:-}"
    if [ -n "${value}" ]; then
        print_set "${var}" "${value}"
    else
        print_unset "${var}"
    fi
done

echo
