#!/usr/bin/env bash
# English technology keywords from an extracted job-description.txt.
# English surfaces are scanned first, then Finnish or Swedish.

PATH_SCR_FN_KWD="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_KWD

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_KWD}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_KWD}/../logging/log.sh"

# Print en, fi, or sv for the second scan. English text has no second scan.
keyword_local_lang() {
    local lang="${1}"
    case "${lang}" in
    sv) printf '%s\n' "sv" ;;
    en) printf '%s\n' "" ;;
    *) printf '%s\n' "fi" ;;
    esac
}

# Write keyword and category lists for one plain-text file.
extract_keywords() {
    local text="${1}"
    local lang="${2}"
    local dest="${3}"
    local categories="${4}"
    local dict="${5:-${DUUNI_ROOT}/${DB_FILE_KW_SKILLS_L}}"
    local local_lang
    if [ ! -s "${text}" ] || [ ! -s "${dict}" ]; then
        dbot_error "Keywords" "Missing text or dictionary (${text}, ${dict})"
        print_error "Missing ${text} or ${dict}"
        return 1
    fi
    local_lang="$(keyword_local_lang "${lang}")"
    : > "${categories}.part"
    awk -F '\t' -v local_lang="${local_lang}" -v cat_file="${categories}.part" '
        NR == FNR {
            if (FNR == 1) next
            n++
            en[n] = $1
            surface[n] = tolower($2)
            dictlang[n] = $3
            category[n] = $4
            next
        }
        {
            raw = tolower($0)
            gsub(/[^[:alnum:]#+.\/ -]/, " ", raw)
            gsub(/[-_]/, " ", raw)
            gsub(/[[:space:]]+/, " ", raw)
            body = body " " raw
        }
        END {
            gsub(/[[:space:]]+/, " ", body)
            body = " " body " "
            if (body !~ /^[[:space:]]*$/) {
                for (pass = 1; pass <= 2; pass++) {
                    for (i = 1; i <= n; i++) {
                        if (pass == 1 && dictlang[i] != "en") continue
                        if (pass == 2 && (local_lang == "" || dictlang[i] != local_lang)) continue
                        if (seen[en[i]]) continue
                        if (hit(body, surface[i], dictlang[i])) {
                            seen[en[i]] = 1
                            order[++found] = en[i]
                            cat_of[en[i]] = category[i]
                        }
                    }
                }
                for (i = 1; i <= found; i++) print order[i]
                for (i = 1; i <= found; i++) {
                    cat = cat_of[order[i]]
                    if (cat == "") continue
                    if (bucket[cat] == "") bucket[cat] = order[i]
                    else bucket[cat] = bucket[cat] ", " order[i]
                    if (!listed[cat]) cats[++nc] = cat
                    listed[cat] = 1
                }
                for (i = 1; i <= nc; i++) print cats[i] "\t" bucket[cats[i]] > cat_file
                close(cat_file)
            }
        }
        function hit(text, form, lang,    token, rest, stem) {
            if (form == "" || length(form) < 2) return 0
            gsub(/[-_]/, " ", form)
            gsub(/[[:space:]]+/, " ", form)
            if (index(text, " " form " ") > 0) return 1
            if (length(form) < 6) return 0
            stem = ""
            if (lang != "en" && length(form) >= 8) stem = substr(form, 1, 6)
            rest = text
            while (match(rest, /[[:alnum:]]+/)) {
                token = substr(rest, RSTART, RLENGTH)
                if (length(token) >= length(form) && index(token, form) == 1) return 1
                if (stem != "" && length(token) >= length(form) && index(token, stem) == 1) return 1
                rest = substr(rest, RSTART + RLENGTH)
            }
            return 0
        }
    ' "${dict}" "${text}" > "${dest}.part"
    mv "${dest}.part" "${dest}"
    mv "${categories}.part" "${categories}"
}

# Store the English keyword list on meta.json.
write_job_keywords() {
    local text="${1}"
    local meta="${2}"
    local lang="${3}"
    local keywords="${4}"
    local categories="${5}"
    local dict="${6:-}"
    local words_key="${7:-${DB_PROP_KYW}}"
    local cats_key="${8:-${DB_PROP_CAT}}"
    local tmp
    if [ -n "${dict}" ]; then
        extract_keywords "${text}" "${lang}" "${keywords}" "${categories}" "${dict}" || return 1
    else
        extract_keywords "${text}" "${lang}" "${keywords}" "${categories}" || return 1
    fi
    tmp="${meta}.part"
    jq --arg words_key "${words_key}" --arg cats_key "${cats_key}" \
        --rawfile kw "${keywords}" --rawfile cats "${categories}" \
        '. + {($words_key): ($kw | split("\n") | map(select(length > 0))), ($cats_key): ($cats | split("\n") | map(select(length > 0)))}' "${meta}" > "${tmp}"
    mv "${tmp}" "${meta}"
}
