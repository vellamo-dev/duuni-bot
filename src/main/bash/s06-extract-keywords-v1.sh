#!/usr/bin/env bash
# Step 6 - s06-extract-keywords-v1.sh
# Scan job-description.txt against the skills' dictionary.
set -u
set -E

PATH_SCR_S06="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_S06

# Dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_S06}/duuni-bot.conf.sh"
fi
source "${PATH_SCR_S06}/fn/conf/paths.sh"
source "${PATH_SCR_S06}/fn/progress/report.sh"
source "${PATH_SCR_S06}/fn/job/keywords.sh"
source "${PATH_SCR_S06}/fn/meta/time.sh"
source "${PATH_SCR_S06}/fn/logging/log.sh"

dbot_trap_errors "Skills keywords"
dbot_log "Skills keywords" "Starting keyword extraction"

# Parse --reset to ignore previous detection and rewrite the keyword data.
RESET_KEYWORDS=0
for arg in "$@"; do
    case "${arg}" in
    --reset)
        dbot_log "Skills keywords" "Reset requested - ignoring previous detection"
        RESET_KEYWORDS=1
        ;;
    esac
done

extract_jobs_keywords_v1() {
    local dir item slug total width n text meta lang keywords categories dict keywords_count start elapsed
    local extracted_count skipped_count failed_count
    dir="$(path_of_data_items_dir "${DB_DIR_JOBS}")"
    dbot_log "Skills keywords" "Extracting  keywords from ${dir}"
    if [ ! -d "${dir}" ]; then
        dbot_error "Skills keywords" "Missing jobs directory ${dir}"
        print_error "Missing ${dir}"
        return 1
    fi
    dict="${DUUNI_ROOT}/${DB_FILE_KW_SKILLS}"
    if [ ! -s "${dict}" ]; then
        dbot_error "Skills keywords" "Missing dictionary ${dict}"
        print_error "Missing ${dict}"
        return 1
    fi
    total="$(find "${dir}" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
    width="$(progress_width "${total}")"
    n=0
    extracted_count=0
    skipped_count=0
    failed_count=0
    print_step_start "Extracting keywords for ${total} items"
    start="$(epoch_now)"
    for item in "${dir}"/*; do
        [ -d "${item}" ] || continue
        slug="$(basename "${item}")"
        n=$((n + 1))
        text="${item}/${DB_FILE_JOB_DESCRIPTION_TXT}"
        meta="${item}/${DB_FILE_META_JSON}"
        keywords="${item}/${DB_FILE_JOB_KEYWORDS_V1}"
        categories="${item}/${DB_FILE_JOB_KEYWORDS_V1_CAT}"
        if [ "${RESET_KEYWORDS}" -eq 0 ] && [ -s "${keywords}" ] && jq --arg k "${DB_PROP_KYW_SKILLS}" -e 'has($k)' "${meta}" >/dev/null 2>&1; then
            print_progress "${width}" "${n}" "${slug}" "${DB_MARK_SKIP}"
            skipped_count=$((skipped_count + 1))
            continue
        fi
        if [ ! -s "${text}" ] || [ ! -s "${meta}" ]; then
            dbot_error "Skills keywords" "Missing text or meta for ${slug}"
            print_progress "${width}" "${n}" "${slug}" "${DB_MARK_FAIL}" >&2
            failed_count=$((failed_count + 1))
            continue
        fi
        lang="$(jq -r --arg k "${DB_PROP_JOB_LANGUAGE}" '.[$k] // "fi"' "${meta}")"
        print_progress "${width}" "${n}" "${slug}"
        if ! write_job_keywords "${text}" "${meta}" "${lang}" "${keywords}" "${categories}" "${dict}" "${DB_PROP_KYW_SKILLS}" "${DB_PROP_CAT_SKILLS}"; then
            print_progress "${width}" "${n}" "${slug}" "${DB_MARK_FAIL}" >&2
            failed_count=$((failed_count + 1))
            continue
        fi
        extracted_count=$((extracted_count + 1))
    done
    elapsed=$(( $(epoch_now) - start ))
    keywords_count="$(find "${dir}" -name "${DB_FILE_JOB_KEYWORDS_V1}" | wc -l | tr -d ' ')"
    dbot_log "Skills keywords" "Extracted ${extracted_count}, skipped ${skipped_count}, failed ${failed_count} (${keywords_count} keyword files) in $(format_duration "${elapsed}")"
    print_step_end "Keywords ${keywords_count} in ${dir} in $(format_duration "${elapsed}")"
}

extract_jobs_keywords_v1

dbot_log "Skills keywords" "Keywords extraction completed"
