#!/usr/bin/env bash
# Checks that the system meets the application requirements.
# bash check-system.sh

set -u

# Terminal colours.
GREEN=$'\033[32m'
RED=$'\033[31m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# Number of failed checks. 0 means the system is ready.
problems=0

ok()   { printf "  ${GREEN}✓${RESET} %s\n" "$1"; }
fail() { printf "  ${RED}✗${RESET} %s\n" "$1"; problems=$((problems + 1)); }

# Run a check. Arguments: a label followed by a command (or function) that
# returns success (0) when the requirement is met.
check() {
    local label="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        ok "${label}"
    else
        fail "${label}"
    fi
}

# Compare two dotted numeric versions. Returns success when $1 >= $2.
# Pure awk so it works with both BSD (macOS) and GNU (Linux) awk.
version_ge() {
    awk -v a="$1" -v b="$2" 'BEGIN {
        na = split(a, A, /[.]/)
        nb = split(b, B, /[.]/)
        n = (na > nb ? na : nb)
        for (i = 1; i <= n; i++) {
            av = (i <= na ? A[i] : 0) + 0
            bv = (i <= nb ? B[i] : 0) + 0
            if (av > bv) exit 0
            if (av < bv) exit 1
        }
        exit 0
    }'
}

# --- Dependency predicates -------------------------------------------------

bash_is_5()    { [ "${BASH_VERSINFO[0]:-0}" -ge 5 ]; }
have_curl()    { command -v curl    >/dev/null 2>&1; }
have_jq()      { command -v jq      >/dev/null 2>&1; }
have_htmlq()   { command -v htmlq   >/dev/null 2>&1; }
have_pandoc()  { command -v pandoc  >/dev/null 2>&1; }
have_python3() { command -v python3 >/dev/null 2>&1; }
have_fastlang() { python3 -c 'import fast_langdetect' >/dev/null 2>&1; }
have_model()   { [ -f "${MODEL_PATH}" ]; }

# macOS 12.0 (Monterey) is the oldest release supported by current Homebrew,
# which is how bash 5, htmlq and pandoc are installed on macOS.
macos_is_min() {
    local v
    v="$(sw_vers -productVersion 2>/dev/null)" || return 1
    version_ge "${v}" "${MACOS_MIN}"
}

# Linux kernel 4.15 (glibc 2.27) is the floor for the bundled tools; a modern
# distribution (Ubuntu 20.04+, Debian 11+, Fedora 32+, RHEL 9+) ships Bash 5.
kernel_is_min() {
    local v
    v="$(uname -r 2>/dev/null)" || return 1
    v="${v%%-*}"
    version_ge "${v}" "${KERNEL_MIN}"
}

# --- Platform detection ----------------------------------------------------

SCRIPT_DIR="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
MODEL_PATH="${SCRIPT_DIR}/assets/fasttext/lid.176.ftz"
MACOS_MIN="12.0"
KERNEL_MIN="4.15"

os_kind="$(uname -s)"

echo
echo "${BOLD}Checking system compatibility${RESET}"
echo "=============================="

case "${os_kind}" in
Darwin)
    echo "Platform: macOS $(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
    echo
    check "macOS ${MACOS_MIN} (Monterey) or newer" macos_is_min
    ;;
Linux)
    echo "Platform: Linux (kernel $(uname -r 2>/dev/null || echo 'unknown'))"
    echo
    check "Linux kernel ${KERNEL_MIN} or newer" kernel_is_min
    ;;
*)
    echo
    printf "  ${RED}✗${RESET} %s is not supported.\n" "${os_kind}"
    echo "  Duuni-bot runs on macOS or Linux only."
    echo
    exit 1
    ;;
esac

check "Bash 5 or newer (found ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]})" bash_is_5
check "curl"                              have_curl
check "jq"                                have_jq
check "htmlq"                             have_htmlq
check "pandoc"                            have_pandoc
check "python3"                           have_python3
check "Python package fast-langdetect"    have_fastlang
check "Language model lid.176.ftz"        have_model

echo
if [ "${problems}" -eq 0 ]; then
    printf "${GREEN}System is OK - all requirements are met.${RESET}\n"
else
    printf "${RED}System needs additional components.${RESET}\n"
    echo
    echo "Install the missing components:"
    case "${os_kind}" in
    Darwin)
        echo "  # macOS (Homebrew):"
        echo "  brew install bash curl jq pandoc htmlq python3"
        echo "  python3 -m pip install --user fast-langdetect"
        ;;
    Linux)
        if command -v dnf >/dev/null 2>&1; then
            echo "  # Fedora / RHEL:"
            echo "  sudo dnf install bash curl jq pandoc python3 python3-pip"
        elif command -v apt-get >/dev/null 2>&1; then
            echo "  # Debian / Ubuntu:"
            echo "  sudo apt-get install bash curl jq pandoc python3 python3-pip"
        else
            echo "  # Install with your distribution's package manager:"
            echo "  #   bash, curl, jq, pandoc, python3, python3-pip"
        fi
        echo "  # htmlq (needs a Rust toolchain, or grab a binary from the releases):"
        echo "  cargo install htmlq"
        echo "  python3 -m pip install --user fast-langdetect"
        ;;
    esac
fi
echo
