#!/usr/bin/env bash
# Language of extracted job-description.txt files. Uses assets/py/fast-langdetect.

PATH_SCR_FN_LGD="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_LGD

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_LGD}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_LGD}/../conf/paths.sh"
source "${PATH_SCR_FN_LGD}/../progress/report.sh"
source "${PATH_SCR_FN_LGD}/../logging/log.sh"

# Install fast-langdetect on first use. Later runs only import it.
require_fast_langdetect() {
    if python3 -c 'import fast_langdetect' >/dev/null 2>&1; then
        return 0
    fi
    echo "Installing fast-langdetect" >&2
    python3 -m pip install --user fast-langdetect
}

# Fail with the path that is actually absent.
require_lang_file() {
    local label="${1}"
    local path="${2}"
    if [ ! -f "${path}" ]; then
        dbot_error "Language" "Missing ${label}: ${path}"
        print_error "Missing ${label}: ${path}"
        return 1
    fi
}

# Detect the language for every job that lacks jobLanguage and store it on
# meta.json. One Python process loads the fasttext model a single time.
detect_jobs_language() {
    local dir item slug meta text script model list lang total width n
    local detected_count skipped_count failed_count pending
    dir="$(path_of_data_items_dir "${DB_DIR_JOBS}")"
    dbot_log "Language" "Detecting job languages in ${dir}"
    if [ ! -d "${dir}" ]; then
        dbot_error "Language" "Missing jobs directory ${dir}"
        print_error "Missing ${dir}"
        return 1
    fi
    script="${DUUNI_ROOT}/assets/py/fast-langdetect/detect_batch.py"
    model="${DUUNI_ROOT}/assets/fasttext/lid.176.ftz"
    require_fast_langdetect || return 1
    require_lang_file "language detector" "${script}" || return 1
    require_lang_file "language model" "${model}" || return 1

    total="$(find "${dir}" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
    width="$(progress_width "${total}")"
    n=0
    detected_count=0
    skipped_count=0
    failed_count=0
    list="$(mktemp)"
    print_step_start "Detecting language for ${total} items"
    for item in "${dir}"/*; do
        [ -d "${item}" ] || continue
        slug="$(basename "${item}")"
        meta="${item}/${DB_FILE_META_JSON}"
        text="${item}/${DB_FILE_JOB_DESCRIPTION_TXT}"
        n=$((n + 1))
        if [ ! -s "${meta}" ]; then
            dbot_error "Language" "Missing meta.json for ${slug}"
            print_progress "${width}" "${n}" "${slug}" "${DB_MARK_FAIL}" >&2
            failed_count=$((failed_count + 1))
            continue
        fi
        if jq --arg k "${DB_PROP_JOB_LANGUAGE}" -e 'has($k)' "${meta}" >/dev/null 2>&1; then
            print_progress "${width}" "${n}" "${slug}" "${DB_MARK_SKIP}"
            skipped_count=$((skipped_count + 1))
            continue
        fi
        if [ ! -s "${text}" ]; then
            dbot_error "Language" "Missing extracted text for ${slug}"
            print_progress "${width}" "${n}" "${slug}" "${DB_MARK_FAIL}" >&2
            failed_count=$((failed_count + 1))
            continue
        fi
        print_progress "${width}" "${n}" "${slug}"
        printf '%s\t%s\n' "${slug}" "${text}" >> "${list}"
    done

    pending="$(wc -l < "${list}" | tr -d ' ')"
    if [ "${pending}" -gt 0 ]; then
        PYTHONWARNINGS="ignore::Warning" python3 "${script}" "${model}" < "${list}" > "${list}.out"
        while IFS="$(printf '\t')" read -r slug lang; do
            [ -n "${slug:-}" ] || continue
            meta="${dir}/${slug}/${DB_FILE_META_JSON}"
            tmp="${meta}.part"
            jq --arg lang "${lang}" --arg k "${DB_PROP_JOB_LANGUAGE}" '. + {($k): $lang}' "${meta}" > "${tmp}"
            mv "${tmp}" "${meta}"
            detected_count=$((detected_count + 1))
        done < "${list}.out"
    fi
    rm -f "${list}" "${list}.out"
    dbot_log "Language" "Detected ${detected_count}, skipped ${skipped_count}, failed ${failed_count} languages"
    print_step_end "Detected ${detected_count}, skipped ${skipped_count}, failed ${failed_count} languages"
}
