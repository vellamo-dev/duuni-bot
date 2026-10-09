#!/usr/bin/env bash
# Download listed job pages.

PATH_SCR_FN_DNL="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_DNL

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_DNL}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_DNL}/../conf/paths.sh"
source "${PATH_SCR_FN_DNL}/../job/item.sh"
source "${PATH_SCR_FN_DNL}/../job/store.sh"
source "${PATH_SCR_FN_DNL}/../http/request.sh"
source "${PATH_SCR_FN_DNL}/../meta/time.sh"
source "${PATH_SCR_FN_DNL}/../progress/report.sh"
source "${PATH_SCR_FN_DNL}/../logging/log.sh"

# Save one listed job page, skipping a file that already exists.
save_job_page() {
    local dir="${1}"
    local slug="${2}"
    local url="${3}"
    local title="${4}"
    local width="${5}"
    local n="${6}"
    local item out downloaded tmp
    item="$(job_item_dir "${dir}" "${slug}")"
    out="${item}/${DB_FILE_JOB_RAW}"
    downloaded="${item}/${DB_FILE_META_DOWNLOADED}"
    restore_listed_job "${item}" "${slug}"
    mkdir -p "${item}"
    rm -f "${item}/${DB_FILE_META_REMOVED}"
    adopt_legacy_html "${item}" "${dir}/${slug}.html"
    if [ -s "${out}" ]; then
        ensure_downloaded_stamp "${item}" || true
        print_progress "${width}" "${n}" "${title}" "${DB_MARK_SKIP}"
        skipped_count=$((skipped_count + 1))
        return 0
    fi
    print_progress "${width}" "${n}" "${title}"
    tmp="${out}.part"
    if ! download_page "${url}" "${tmp}"; then
        rm -f "${tmp}"
        print_progress "${width}" "${n}" "${title}" "${DB_MARK_FAIL}" >&2
        failed_count=$((failed_count + 1))
        return 0
    fi
    mv "${tmp}" "${out}"
    write_stamp "${downloaded}" "$(utc_now)"
    downloaded_count=$((downloaded_count + 1))
    sleep "${DB_SLEEP}"
}

# Download every job page named in the job-address table.
download_listed_jobs() {
    local in="${1}"
    local dir="${2}"
    local pages slug url title total width n limit
    local curl_overhead estimated start elapsed
    local downloaded_count skipped_count failed_count
    pages="$(mktemp)"
    tail -n +2 "${in}" >"${pages}"
    total="$(awk -F'\t' 'NF >= 3 && $1 != "" && $2 != ""' "${pages}" | wc -l | tr -d ' ')"
    limit="$(job_limit)"
    if [ "${limit}" -gt 0 ] && [ "${total}" -gt "${limit}" ]; then
        total="${limit}"
        dbot_log "Jobs downloader" "Limited to ${limit} jobs (DB_LIMIT_JOBS)"
    fi
    width="$(progress_width "${total}")"
    n=0
    downloaded_count=0
    skipped_count=0
    failed_count=0
    # Estimate the run time: per job, the configured sleep plus the measured
    # curl/processing time. curl_overhead=0.75s was derived from a 1260-job
    # run that took 36m 49s at DB_SLEEP=1 (2209s / 1260 - 1s).
    curl_overhead=0.75
    estimated="$(awk -v n="${total}" -v s="${DB_SLEEP:-0}" -v o="${curl_overhead}" \
        'BEGIN { printf "%.0f\n", n * (s + o) }')"
    dbot_log "Jobs downloader" "Downloading ${total} job pages (estimated $(format_duration "${estimated}"))"
    print_step_start "Downloading ${total} items (estimated $(format_duration "${estimated}"))"
    start="$(epoch_now)"
    while IFS="$(printf '\t')" read -r slug url title; do
        [ -n "${slug:-}" ] && [ -n "${url:-}" ] || continue
        slug_is_safe "${slug}" || continue
        if [ "${limit}" -gt 0 ] && [ "${n}" -ge "${limit}" ]; then
            break
        fi
        n=$((n + 1))
        save_job_page "${dir}" "${slug}" "${url}" "${title}" "${width}" "${n}"
    done <"${pages}"
    elapsed=$(( $(epoch_now) - start ))
    rm -f "${pages}"
    dbot_log "Jobs downloader" "Processed ${total} job pages: ${downloaded_count} downloaded, ${skipped_count} skipped, ${failed_count} failed in $(format_duration "${elapsed}")"
    print_step_end "Processed ${total} items: ${downloaded_count} downloaded, ${skipped_count} skipped, ${failed_count} failed in $(format_duration "${elapsed}")"
}
