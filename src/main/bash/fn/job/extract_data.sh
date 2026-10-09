#!/usr/bin/env bash
# Step 4: extract job metadata and the description pages.

PATH_SCR_FN_EJD="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_EJD

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_EJD}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_EJD}/../conf/paths.sh"
source "${PATH_SCR_FN_EJD}/../job/description.sh"
source "${PATH_SCR_FN_EJD}/../job/description_text.sh"
source "${PATH_SCR_FN_EJD}/../job/meta.sh"
source "${PATH_SCR_FN_EJD}/../progress/report.sh"
source "${PATH_SCR_FN_EJD}/../meta/time.sh"
source "${PATH_SCR_FN_EJD}/../logging/log.sh"

# Return success when meta.json has every field produced by write_job_meta,
# with the required fields non-empty.
meta_is_complete() {
    local meta="${1}"
    [ -s "${meta}" ] || return 1
    jq -e \
        --arg kSlug "${DB_PROP_JOB_SLUG}" \
        --arg kId "${DB_PROP_JOB_ID}" \
        --arg kGrp "${DB_PROP_JOB_GRP_TAG}" \
        --arg kTitle "${DB_PROP_JOB_TITLE}" \
        --arg kEmployer "${DB_PROP_JOB_EMPLOYER}" \
        --arg kPublished "${DB_PROP_JOB_PUBLISHED}" \
        --arg kExpires "${DB_PROP_JOB_EXPIRES}" \
        --arg kUrl "${DB_PROP_JOB_URL_CANONICAL}" \
        --arg kLocation "${DB_PROP_JOB_LOCATION}" \
        --arg kBusiness "${DB_PROP_JOB_BUSINESS_ID}" \
        --arg kIndustry "${DB_PROP_JOB_INDUSTRY}" \
        --arg kEmployment "${DB_PROP_JOB_EMPLOYMENT_TYPE}" \
        --arg kSalary "${DB_PROP_JOB_SALARY_INFO}" \
        --arg kData "${DB_PROP_JOB_DATA_PATH}" \
        --arg kDesc "${DB_PROP_JOB_DESC_PATH}" \
        --arg kText "${DB_PROP_JOB_TEXT_PATH}" \
        --arg kExtracted "${DB_PROP_JOB_EXTRACTED}" \
        --arg kDownloaded "${DB_PROP_JOB_DOWNLOADED}" \
        'has($kSlug) and has($kId) and has($kGrp) and has($kTitle) and has($kEmployer) and has($kPublished) and has($kExpires) and has($kUrl) and has($kLocation) and has($kBusiness) and has($kIndustry) and has($kEmployment) and has($kSalary) and has($kData) and has($kDesc) and has($kText) and has($kExtracted) and has($kDownloaded)
         and .[$kSlug] != "" and .[$kId] != "" and .[$kGrp] != "" and .[$kTitle] != "" and .[$kUrl] != "" and .[$kData] != "" and .[$kDesc] != "" and .[$kText] != "" and .[$kExtracted] != "" and .[$kDownloaded] != ""' "${meta}" >/dev/null 2>&1
}

# Extract meta.json, job-data.html, and job-description.html for one job directory.
extract_job_item() {
    local item="${1}"
    local slug="${2}"
    local raw meta data description text title
    raw="${item}/${DB_FILE_JOB_RAW}"
    meta="${item}/${DB_FILE_META_JSON}"
    data="${item}/${DB_FILE_JOB_DATA}"
    description="${item}/${DB_FILE_JOB_DESCRIPTION}"
    text="${item}/${DB_FILE_JOB_DESCRIPTION_TXT}"
    if [ ! -s "${raw}" ]; then
        dbot_error "Jobs data" "Missing raw page ${raw}"
        print_error "Missing ${raw}"
        return 1
    fi
    write_job_meta "${raw}" "${meta}" "${slug}" || return 1
    title="$(jq -r --arg k "${DB_PROP_JOB_TITLE}" '.[$k]' "${meta}")"
    write_job_data "${raw}" "${data}" "${title}" || return 1
    write_job_description "${raw}" "${description}" "${title}" || return 1
    write_job_description_text "${description}" "${text}" || return 1
}

# Extract missing or outdated job metadata from every saved job directory.
extract_jobs_data() {
    local dir item slug total width n title meta_count start elapsed
    local extracted_count skipped_count failed_count
    dir="$(path_of_data_items_dir "${DB_DIR_JOBS}")"
    dbot_log "Jobs data" "Extracting job data from ${dir}"
    if [ ! -d "${dir}" ]; then
        dbot_error "Jobs data" "Missing jobs directory ${dir}"
        print_error "Missing ${dir}"
        return 1
    fi
    total="$(find "${dir}" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
    width="$(progress_width "${total}")"
    n=0
    extracted_count=0
    skipped_count=0
    failed_count=0
    print_step_start "Extracting ${total} items"
    start="$(epoch_now)"
    for item in "${dir}"/*; do
        [ -d "${item}" ] || continue
        slug="$(basename "${item}")"
        n=$((n + 1))
        if meta_is_complete "${item}/${DB_FILE_META_JSON}" && [ -s "${item}/${DB_FILE_JOB_DATA}" ] && [ -s "${item}/${DB_FILE_JOB_DESCRIPTION}" ] && [ -s "${item}/${DB_FILE_JOB_DESCRIPTION_TXT}" ]; then
            title="$(jq -r --arg k "${DB_PROP_JOB_TITLE}" '.[$k] // empty' "${item}/${DB_FILE_META_JSON}" 2>/dev/null || true)"
            print_progress "${width}" "${n}" "${title:-${slug}}" "${DB_MARK_SKIP}"
            skipped_count=$((skipped_count + 1))
            continue
        fi
        print_progress "${width}" "${n}" "${slug}"
        if ! extract_job_item "${item}" "${slug}"; then
            print_progress "${width}" "${n}" "${slug}" "${DB_MARK_FAIL}" >&2
            failed_count=$((failed_count + 1))
            continue
        fi
        extracted_count=$((extracted_count + 1))
    done
    elapsed=$(( $(epoch_now) - start ))
    meta_count="$(find "${dir}" -name "${DB_FILE_META_JSON}" | wc -l | tr -d ' ')"
    dbot_log "Jobs data" "Extracted ${extracted_count}, skipped ${skipped_count}, failed ${failed_count} (${meta_count} meta files) in $(format_duration "${elapsed}")"
    print_step_end "Meta ${meta_count} in ${dir} in $(format_duration "${elapsed}")"
}
