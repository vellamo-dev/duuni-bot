#!/usr/bin/env bash
# Configuration for Duuni-Bot

DUUNI_ROOT="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# Duunitori job extractor.

# Subcommand files executed via run.sh.
# Index 0 is a placeholder so step numbers stay 1-based (step 1 == s01).
DB_RS=(
    ""
    s01-extract-listing-pages-addresses.sh
    s02-extract-job-pages-addresses.sh
    s03-download-job-pages-raw-data.sh
    s04-extract-jobs-data.sh
    s05-detect-language.sh
    s06-extract-keywords-v1.sh
    s07-extract-keywords-v2.sh
)

# DB_PATH_DATA is the base directory for all data.
# It may be relative to this file, absolute, or ~/.
# The other data paths are relative to DB_PATH_DATA unless they are absolute or ~/.
DB_PATH_DATA="/working/data"
# Directory names
DB_DIR_JOBS="jobs"
DB_DIR_JOBS_REMOVED="jobs-removed"
DB_DIR_LINKS="links"
DB_DIR_LISTS="lists"
DB_DIR_LOGS="logs"
DB_DIR_LOG_ERR="errors"
DB_DIR_LOG_INF="info"
# File names
DB_FILE_JOB_DATA="job-data.html"
DB_FILE_JOB_DESCRIPTION="job-description.html"
DB_FILE_JOB_DESCRIPTION_TXT="job-description.txt"
DB_FILE_JOB_KEYWORDS_V1="job-keywords-deep.txt"
DB_FILE_JOB_KEYWORDS_V1_CAT="job-keyword-categories-deep.tsv"
DB_FILE_JOB_KEYWORDS_V2="job-keywords.txt"
DB_FILE_JOB_KEYWORDS_V2_CAT="job-keyword-categories.tsv"
DB_FILE_JOB_PAGES="job-pages.tsv"
DB_FILE_JOB_RAW="raw.html"
DB_FILE_LISTING_PAGES="listing-pages.tsv"
DB_FILE_FAILED="failed.tsv"
DB_FILE_META_DOWNLOADED="meta-downloaded.txt"
DB_FILE_META_JSON="meta.json"
DB_FILE_META_REMOVED="meta-removed.txt"
DB_FILE_KW_SKILLS="assets/skills/keywords-skills.tsv"
DB_FILE_KW_SKILLS_L="assets/skills/keywords-skills-large.tsv"

# Curl headers
DB_BROWSER="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36"
DB_ACCEPT="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8"
DB_ACCEPT_LANGUAGE="fi-FI,fi;q=0.9,en-US;q=0.8,en;q=0.7"
DB_ORIGIN="https://duunitori.fi"

# Starting point
DB_START_URL="https://duunitori.fi/tyopaikat/ala/tieto-tietoliikennetekniikka"

# Behavior
DB_SLEEP="0.8"
DB_LIMIT_JOBS=""
DB_LOG_RETENTION_DAYS="30"
DB_REMOVED_RETENTION_DAYS="30"
DB_MARK_SKIP="skip"
DB_MARK_FAIL="fail"
DB_MARK_PURGE=".purge"

# Templates (relative to a conf file)
DB_TPL_JOB_INFO_HTML="assets/templates/job-info.html"

# JSON Properties
# Skills keyword extraction (step 6)
DB_PROP_KYW_SKILLS="jobSkillsKeywords"
DB_PROP_CAT_SKILLS="jobSkillsCategories"
# English keyword extraction (step 7)
DB_PROP_KYW="jobExtSkillsKeywords"
DB_PROP_CAT="jobExtSkillsCategories"
# Job language (step 5)
DB_PROP_JOB_LANGUAGE="jobLanguage"
# Core job metadata written to meta.json (step 4)
DB_PROP_JOB_SLUG="jobSlug"
DB_PROP_JOB_ID="jobID"
DB_PROP_JOB_GRP_TAG="jobGrpTag"
DB_PROP_JOB_TITLE="jobTitle"
DB_PROP_JOB_EMPLOYER="jobEmployer"
DB_PROP_JOB_PUBLISHED="jobPublished"
DB_PROP_JOB_EXTRACTED="jobExtracted"
DB_PROP_JOB_DOWNLOADED="jobDownloaded"
DB_PROP_JOB_EXPIRES="jobExpires"
DB_PROP_JOB_URL_CANONICAL="jobUrlCanonical"
DB_PROP_JOB_LOCATION="jobLocation"
DB_PROP_JOB_BUSINESS_ID="jobBusinessId"
DB_PROP_JOB_INDUSTRY="jobIndustry"
DB_PROP_JOB_EMPLOYMENT_TYPE="jobEmploymentType"
DB_PROP_JOB_SALARY_INFO="jobSalaryInfo"
DB_PROP_JOB_DATA_PATH="pathDataHtml"
DB_PROP_JOB_DESC_PATH="pathDescriptionHtml"
DB_PROP_JOB_TEXT_PATH="pathDescriptionTxt"

# Step 7 (s07-extract-keywords-v2.sh) in the automated chain (duuni-bot.sh).
# This step is time-consuming because it scans every job description against
# a large dictionary, so it can be skipped when not needed.
# 1 = run step 7, 0 = skip it.
DB_ENABLE_ST_EK2=0

# Environment overrides
# Optional environment variables that override the configured defaults above,
# so the configuration can be reused without editing this file.

# Replace the data directory when DB_ENV_PATH_DATA points to an existing directory.
if [ -n "${DB_ENV_PATH_DATA:-}" ] && [ -d "${DB_ENV_PATH_DATA}" ]; then
    DB_PATH_DATA="${DB_ENV_PATH_DATA}"
fi

# Run (1) or skip (0) step 7 in the automated chain.
if [ -n "${DB_ENV_ENABLE_ST_EK2:-}" ]; then
    DB_ENABLE_ST_EK2="${DB_ENV_ENABLE_ST_EK2}"
fi

# Sleep time between downloads.
if [ -n "${DB_ENV_DB_SLEEP:-}" ]; then
    DB_SLEEP="${DB_ENV_DB_SLEEP}"
fi

# Browser user-agent header.
if [ -n "${DB_ENV_DB_BROWSER:-}" ]; then
    DB_BROWSER="${DB_ENV_DB_BROWSER}"
fi

# Log retention in days.
if [ -n "${DB_ENV_LOG_RETENTION_DAYS:-}" ]; then
    DB_LOG_RETENTION_DAYS="${DB_ENV_LOG_RETENTION_DAYS}"
fi

# Removed-job retention in days (after which the bot marks them for purge).
if [ -n "${DB_ENV_REMOVED_RETENTION_DAYS:-}" ]; then
    DB_REMOVED_RETENTION_DAYS="${DB_ENV_REMOVED_RETENTION_DAYS}"
fi

# Cap the number of jobs processed (empty or 0 = no limit).
if [ -n "${DB_ENV_LIMIT_JOBS:-}" ]; then
    DB_LIMIT_JOBS="${DB_ENV_LIMIT_JOBS}"
fi