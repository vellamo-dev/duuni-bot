#!/usr/bin/env bash
# HTTP requests. Uses DB_BROWSER, DB_ACCEPT and DB_ACCEPT_LANGUAGE.
# A failed request writes one line to stderr: "Could not fetch <url>: <code>".

PATH_SCR_FN_HTG="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_HTG

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_HTG}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_HTG}/../logging/log.sh"

# Download a URL to a file and fail unless the status is 2xx.
http_get() {
    local url="${1}"
    local dest="${2}"
    local err code status
    err="$(mktemp "${TMPDIR:-/tmp}/duuni-curl.XXXXXX")"
    status=0
    code="$(
        curl -sS --compressed \
            -A "${DB_BROWSER}" \
            -H "Accept: ${DB_ACCEPT}" \
            -H "Accept-Language: ${DB_ACCEPT_LANGUAGE}" \
            -H "Upgrade-Insecure-Requests: 1" \
            -o "${dest}" \
            -w '%{http_code}' \
            -- "${url}" 2>"${err}"
    )" || status=${?}
    case "${code}" in
    2??)
        if [ "${status}" -eq 0 ]; then
            rm -f "${err}"
            return 0
        fi
        ;;
    esac
    if [ "${#code}" -eq 3 ] && [ "${code}" != "000" ]; then
        print_error "Could not fetch ${url}: HTTP ${code}"
        dbot_error "HTTP" "Could not fetch ${url}: HTTP ${code}"
    else
        print_error "Could not fetch ${url}: curl ${status}"
        dbot_error "HTTP" "Could not fetch ${url}: curl ${status}"
    fi
    record_failed_url "${url}"
    rm -f "${err}" "${dest}"
    return 1
}

# Append a failed URL to the failed-URL list for later rescan.
record_failed_url() {
    local url="${1}"
    local failed
    failed="$(path_of_data_item "${DB_DIR_LINKS}/${DB_FILE_FAILED}" 2>/dev/null || true)"
    [ -n "${failed}" ] || return 0
    printf '%s\n' "${url}" >> "${failed}" 2>/dev/null || true
    return 0
}

# Fetch a URL and print the response body.
fetch_page() {
    local url="${1}"
    local tmp
    tmp="$(mktemp "${TMPDIR:-/tmp}/duuni-body.XXXXXX")"
    if ! http_get "${url}" "${tmp}"; then
        rm -f "${tmp}"
        return 1
    fi
    cat "${tmp}"
    rm -f "${tmp}"
}

# Download a URL into the destination path.
download_page() {
    local url="${1}"
    local dest="${2}"
    local tmp
    tmp="$(mktemp "${TMPDIR:-/tmp}/duuni-body.XXXXXX")"
    if ! http_get "${url}" "${tmp}"; then
        rm -f "${tmp}"
        return 1
    fi
    mv "${tmp}" "${dest}"
}
