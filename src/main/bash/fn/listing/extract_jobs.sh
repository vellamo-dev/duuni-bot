#!/usr/bin/env bash
# Step 2: save listing pages, then write the job-address table.

PATH_SCR_FN_EXJ="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_EXJ

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_EXJ}/../../duuni-bot.conf.sh"
fi

source "${PATH_SCR_FN_EXJ}/../conf/paths.sh"
source "${PATH_SCR_FN_EXJ}/../listing/download.sh"
source "${PATH_SCR_FN_EXJ}/../listing/files.sh"
source "${PATH_SCR_FN_EXJ}/../listing/cards.sh"
source "${PATH_SCR_FN_EXJ}/../logging/log.sh"

# Write job-pages.tsv from the saved listing HTML files.
write_job_pages() {
    local lists="${1}"
    local out="${2}"
    local files file count limit
    dbot_log "Jobs extractor" "Writing job-pages table to ${out}"
    printf 'slug\turl\ttitle\n' >"${out}"
    files="$(mktemp)"
    listing_files "${lists}" >"${files}"
    while IFS= read -r file; do
        [ -n "${file}" ] || continue
        if ! extract_job_cards <"${file}"; then
            dbot_error "Jobs extractor" "Failed to extract job cards from ${file}"
            print_error "${file} [${DB_MARK_FAIL}]"
            rm -f "${files}"
            return 1
        fi
    done <"${files}" | awk -F'\t' '!seen[$1]++' >>"${out}"
    rm -f "${files}"
    count="$(tail -n +2 "${out}" | wc -l | tr -d ' ')"
    limit="$(job_limit)"
    if [ "${limit}" -gt 0 ] && [ "${count}" -gt "${limit}" ]; then
        awk -v n="${limit}" 'NR <= n + 1' "${out}" >"${out}.part"
        mv "${out}.part" "${out}"
        count="${limit}"
        dbot_log "Jobs extractor" "Limited to ${limit} jobs (DB_LIMIT_JOBS)"
    fi
    dbot_log "Jobs extractor" "${count} jobs stored into ${out}"
    print_step_end "Wrote ${count} jobs to ${out}"
}

# Save listing pages, then extract job addresses from those files.
extract_job_pages() {
    local in out lists pages
    in="$(path_of_data_item "${DB_DIR_LINKS}/${DB_FILE_LISTING_PAGES}")"
    out="$(path_of_data_item "${DB_DIR_LINKS}/${DB_FILE_JOB_PAGES}")"
    lists="$(path_of_data_items_dir "${DB_DIR_LISTS}")"
    dbot_log "Jobs extractor" "Extracting job pages from ${in}"
    if [ ! -f "${in}" ]; then
        dbot_error "Jobs extractor" "Missing listing-pages table ${in}"
        print_error "Missing ${in}"
        return 1
    fi
    mkdir -p "$(dirname "${out}")"
    reset_listing_dir "${lists}"
    download_listing_pages "${in}" "${lists}"
    write_job_pages "${lists}" "${out}"
    pages="$(find "${lists}" -type f -name '*.html' | wc -l | tr -d ' ')"
    dbot_log "Jobs extractor" "${pages} listing pages saved in ${lists}"
    echo "Pages ${pages} in ${lists}"
}
