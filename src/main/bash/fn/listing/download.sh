#!/usr/bin/env bash
# Download listing pages into lists/<id>.html.

PATH_SCR_FN_LDN="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_LDN

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_LDN}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_LDN}/../conf/paths.sh"
source "${PATH_SCR_FN_LDN}/../progress/report.sh"
source "${PATH_SCR_FN_LDN}/../http/request.sh"
source "${PATH_SCR_FN_LDN}/../meta/time.sh"
source "${PATH_SCR_FN_LDN}/../logging/log.sh"

# Download one listing page into lists/<id>.html.
save_listing_page() {
    local url="${1}"
    local dest="${2}"
    local tmp="${dest}.part"
    if ! download_page "${url}" "${tmp}"; then
        rm -f "${tmp}"
        return 1
    fi
    mv "${tmp}" "${dest}"
}

# Download every listing page named in the address table.
download_listing_pages() {
    local in="${1}"
    local lists="${2}"
    local pages id url total width n dest curl_overhead estimated start elapsed
    pages="$(mktemp)"
    tail -n +2 "${in}" >"${pages}"
    total="$(awk -F'\t' 'NF >= 2 && $1 != "" && $2 != ""' "${pages}" | wc -l | tr -d ' ')"
    width="$(progress_width "${total}")"
    n=0
    # Estimate the run time: per page, the configured sleep plus a per-page
    # allowance for the curl request.
    curl_overhead=0.75
    estimated="$(awk -v n="${total}" -v s="${DB_SLEEP:-0}" -v o="${curl_overhead}" 'BEGIN { printf "%.0f\n", n * (s + o) }')"
    dbot_log "Jobs extractor" "Downloading ${total} listing pages (estimated $(format_duration "${estimated}"))"
    print_step_start "Downloading ${total} listing pages (estimated $(format_duration "${estimated}"))"
    start="$(epoch_now)"
    while IFS="$(printf '\t')" read -r id url _; do
        [ -n "${id:-}" ] && [ -n "${url:-}" ] || continue
        case "${id}" in
        "" | *[!0-9]*) continue ;;
        esac
        n=$((n + 1))
        dest="${lists}/${id}.html"
        print_progress "${width}" "${n}" "${url}"
        if ! save_listing_page "${url}" "${dest}"; then
            rm -f "${pages}"
            print_progress "${width}" "${n}" "${url}" "${DB_MARK_FAIL}" >&2
            return 1
        fi
        sleep "${DB_SLEEP}"
    done <"${pages}"
    elapsed=$(( $(epoch_now) - start ))
    rm -f "${pages}"
    dbot_log "Jobs extractor" "Downloaded ${total} listing pages in $(format_duration "${elapsed}")"
    print_step_end "Downloaded ${total} listing pages in $(format_duration "${elapsed}")"
}
