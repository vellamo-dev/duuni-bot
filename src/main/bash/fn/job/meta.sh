#!/usr/bin/env bash
# Write meta.json for one saved job page.

PATH_SCR_FN_MTA="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_MTA

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_MTA}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_MTA}/../html/htmlq.sh"
source "${PATH_SCR_FN_MTA}/../meta/time.sh"
source "${PATH_SCR_FN_MTA}/../logging/log.sh"
source "${PATH_SCR_FN_MTA}/meta_fields.sh"
source "${PATH_SCR_FN_MTA}/meta_slug.sh"

# Write meta.json for one saved job page.
write_job_meta() {
    local raw="${1}"
    local dest="${2}"
    local slug="${3}"
    local title employer published expires canonical location business industry employment salary job_id job_group data_path description_path text_path tmp
    local extracted_at downloaded_at
    require_htmlq || return 1
    if ! command -v jq >/dev/null 2>&1; then
        dbot_error "Jobs data" "jq is not installed"
        print_error "Missing jq. macOS: brew install jq. Linux: sudo dnf install jq"
        return 1
    fi
    title="$(htmlq -f "${raw}" -w -t 'h1.text--break-word' | sed '/^[[:space:]]*$/d' | head -n 1)"
    employer="$(listing_value "${raw}" "Toiminimi")"
    if [ -z "${employer}" ]; then
        employer="$(page_attr "${raw}" 'meta[property="article:author"]' content)"
    fi
    if [ -z "${employer}" ]; then
        employer="$(posting_field "${raw}" '.hiringOrganization.name')"
    fi
    published="$(page_attr "${raw}" 'meta[property="article:published_time"]' content)"
    expires="$(page_attr "${raw}" 'meta[property="article:expiration_time"]' content)"
    canonical="$(page_attr "${raw}" 'link[rel="canonical"]' href)"
    location="$(listing_value "${raw}" "Työpaikan sijainti")"
    if [ -z "${location}" ]; then
        location="$(posting_field "${raw}" '.jobLocation.address.addressLocality')"
    fi
    business="$(listing_value "${raw}" "Y-tunnus")"
    industry="$(listing_value "${raw}" "Toimiala")"
    employment="$(posting_field "${raw}" 'if (.employmentType | type) == "array" then .employmentType | join(", ") else .employmentType end')"
    salary="$(salary_info "${raw}")"
    job_id="$(job_slug_id "${slug}")"
    job_group="$(job_slug_group "${slug}")"
    data_path="${DB_DIR_JOBS}/${slug}/${DB_FILE_JOB_DATA}"
    description_path="${DB_DIR_JOBS}/${slug}/${DB_FILE_JOB_DESCRIPTION}"
    text_path="${DB_DIR_JOBS}/${slug}/${DB_FILE_JOB_DESCRIPTION_TXT}"
    if [ -z "${title}" ] || [ -z "${canonical}" ] || [ -z "${job_id}" ] || [ -z "${job_group}" ]; then
        dbot_error "Jobs data" "Could not read job title, canonical URL, or slug id from ${raw}"
        print_error "Could not read job title, canonical URL, or slug id from ${raw}"
        return 1
    fi
    extracted_at="$(utc_now)"
    downloaded_at="$(file_created_utc "${raw}")"
    tmp="${dest}.part"
    jq -n \
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
        --arg vSlug "${slug}" \
        --arg vId "${job_id}" \
        --arg vGrp "${job_group}" \
        --arg vTitle "${title}" \
        --arg vEmployer "${employer}" \
        --arg vPublished "${published}" \
        --arg vExpires "${expires}" \
        --arg vUrl "${canonical}" \
        --arg vLocation "${location}" \
        --arg vBusiness "${business}" \
        --arg vIndustry "${industry}" \
        --arg vEmployment "${employment}" \
        --arg vSalary "${salary}" \
        --arg vData "${data_path}" \
        --arg vDesc "${description_path}" \
        --arg vText "${text_path}" \
        --arg vExtracted "${extracted_at}" \
        --arg vDownloaded "${downloaded_at}" \
        '{($kSlug):$vSlug, ($kId):$vId, ($kGrp):$vGrp, ($kTitle):$vTitle, ($kEmployer):$vEmployer, ($kPublished):$vPublished, ($kExpires):$vExpires, ($kUrl):$vUrl, ($kLocation):$vLocation, ($kBusiness):$vBusiness, ($kIndustry):$vIndustry, ($kEmployment):$vEmployment, ($kSalary):$vSalary, ($kData):$vData, ($kDesc):$vDesc, ($kText):$vText, ($kExtracted):$vExtracted, ($kDownloaded):$vDownloaded}' > "${tmp}"
    mv "${tmp}" "${dest}"
}
