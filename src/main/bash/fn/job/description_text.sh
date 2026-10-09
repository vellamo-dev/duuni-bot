#!/usr/bin/env bash
# Readable plain text from job-description.html. Uses pandoc.

PATH_SCR_FN_DTX="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_FN_DTX

# Load dependencies
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_FN_DTX}/../../duuni-bot.conf.sh"
fi
source "${PATH_SCR_FN_DTX}/../logging/log.sh"

# Stop when pandoc is not installed.
require_pandoc() {
    if ! command -v pandoc >/dev/null 2>&1; then
        dbot_error "Jobs data" "pandoc is not installed"
        print_error "Missing pandoc. macOS: brew install pandoc. Linux: sudo dnf install pandoc"
        return 1
    fi
}

# Turn a markdown link into Label (https://...).
# Every '[' is consumed once. A bare bracket is not a link and must not restart the scan.
# Parameter expansion only: macOS Bash 3.2 rejects the previous bracket expression.
plain_link() {
    local line="${1}"
    local out="" before rest label url tail
    while [ "${line}" != "${line#*[}" ]; do
        before="${line%%[*}"
        rest="${line#*[}"
        out="${out}${before}"
        if [ "${out}" != "${out%\\}" ]; then
            out="${out}["
            line="${rest}"
            continue
        fi
        case "${rest}" in
        *']('*)
            label="${rest%%']('*}"
            tail="${rest#*']('}"
            url="${tail%%')'*}"
            if [ "${tail}" != "${url}" ]; then
                line="${tail#*")"}"
                case "${url}" in
                /*) url="${DB_ORIGIN}${url}" ;;
                esac
                case "${url}" in
                "${label}" | "mailto:${label}" | "tel:${label}")
                    out="${out}${label}"
                    ;;
                *)
                    out="${out}${label} (${url})"
                    ;;
                esac
                continue
            fi
            ;;
        esac
        case "${rest}" in
        *']'*)
            label="${rest%%']'*}"
            line="${rest#*']'}"
            out="${out}${label}"
            continue
            ;;
        esac
        out="${out}["
        line="${rest}"
    done
    printf '%s\n' "${out}${line}"
}

# Uppercase a single-line strong element.
# tr does not case ä, ö, or å without a Finnish locale.
plain_heading() {
    local text="${1}"
    text="$(printf '%s' "${text}" | tr '[:lower:]' '[:upper:]')"
    text="${text//ä/Ä}"
    text="${text//ö/Ö}"
    text="${text//å/Å}"
    printf '%s\n' "${text}"
}

# Remove an HTML comment. Pandoc inserts <!-- --> between separate lists.
strip_html_comment() {
    local line="${1}"
    local before rest
    while [ "${line}" != "${line#*<!--}" ]; do
        before="${line%%<!--*}"
        if [ "${line}" = "${line#*-->}" ]; then
            line="${before}"
            break
        fi
        rest="${line#*-->}"
        line="${before}${rest}"
    done
    printf '%s\n' "${line}"
}

# Format pandoc markdown into readable plain text.
# Drop raw HTML blocks left when embeds are not fetched.
format_description_text() {
    local line trimmed indent body level pad previous="" blank=1 raw=0
    while IFS= read -r line || [ -n "${line}" ]; do
        line="${line%$'\\'}"
        line="${line//\{rel=\"noopener nofollow\" target=\"_blank\"\}/}"
        line="${line// / }"
        line="$(strip_html_comment "${line}")"
        trimmed="${line#"${line%%[![:space:]]*}"}"
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
        if [ "${raw}" -eq 1 ]; then
            case "${trimmed}" in
            '```'*) raw=0 ;;
            esac
            continue
        fi
        case "${trimmed}" in
        '```{=html}'*) raw=1; continue ;;
        esac
        line="$(plain_link "${line}")"
        line="${line//\\[/[}"
        line="${line//\\]/]}"
        trimmed="${line#"${line%%[![:space:]]*}"}"
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
        [ -n "${trimmed}" ] || continue
        case "${trimmed}" in
        :::*) continue ;;
        '<!--'*'-->') continue ;;
        esac
        if [[ "${trimmed}" =~ ^[*][*](.+)[*][*]$ ]]; then
            trimmed="$(plain_heading "${BASH_REMATCH[1]}")"
        fi
        trimmed="${trimmed//\*\*/}"
        trimmed="${trimmed#"${trimmed%%[![:space:]]*}"}"
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
        [ -n "${trimmed}" ] || continue
        if [[ "${line}" =~ ^([[:space:]]*)[-*+][[:space:]]+(.*)$ ]]; then
            indent="${#BASH_REMATCH[1]}"
            body="${BASH_REMATCH[2]}"
            level=$((indent / 2))
            if [ "${level}" -lt 1 ]; then
                level=1
            fi
            pad="$(printf '%*s' $((level * 2)) '')"
            if [ "${previous}" != "list" ] && [ "${blank}" -eq 0 ]; then
                printf '\n'
            fi
            printf '%s• %s\n' "${pad}" "${body}"
            previous="list"
            blank=0
            continue
        fi
        if [ "${blank}" -eq 0 ]; then
            printf '\n'
        fi
        printf '%s\n' "${trimmed}"
        previous="text"
        blank=0
    done
    printf '\n'
}

# Write job-description.txt from the saved description page.
# html+raw_html keeps iframe, object, and embed as raw blocks, so pandoc does not request their src.
# --sandbox blocks any remaining external read.
write_job_description_text() {
    local src="${1}"
    local dest="${2}"
    local tmp
    require_pandoc || return 1
    tmp="${dest}.part"
    pandoc --sandbox -f html+raw_html -t markdown --wrap=none "${src}" | format_description_text > "${tmp}"
    mv "${tmp}" "${dest}"
}
