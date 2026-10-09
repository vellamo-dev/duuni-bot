#!/usr/bin/env bash
# Raw job-page field extractors used by write_job_meta.

# Read one info-listing value by its heading.
listing_value() {
    local raw="${1}"
    local heading="${2}"
    local headings values
    headings="$(mktemp)"
    values="$(mktemp)"
    htmlq -f "${raw}" -w -t 'h4.info-listing__heading' | sed '/^[[:space:]]*$/d' > "${headings}"
    htmlq -f "${raw}" -w -t 'div.info-listing__value' | sed '/^[[:space:]]*$/d' > "${values}"
    paste "${headings}" "${values}" | awk -F '\t' -v heading="${heading}" '$1 == heading { print $2; exit }'
    rm -f "${headings}" "${values}"
}

# Read a meta or link attribute from a job page.
page_attr() {
    local raw="${1}"
    local selector="${2}"
    local attribute="${3}"
    htmlq -f "${raw}" -a "${attribute}" "${selector}" | sed -n '1s/^[[:space:]]*//;s/[[:space:]]*$//p'
}

# Read one field from the JobPosting JSON-LD block.
posting_field() {
    local raw="${1}"
    local filter="${2}"
    htmlq -f "${raw}" -t 'script[type="application/ld+json"]' | jq -r "${filter} // empty" 2>/dev/null | head -n 1
}

# Plain text between h2#palkka and the next hr. Empty when the page has no salary block.
salary_info() {
    local raw="${1}"
    local html tmp text
    html="$(
        awk '
            BEGIN { found = 0 }
            {
                chunk = $0
                if (!found) {
                    at = index(chunk, "id=\"palkka\"")
                    if (at == 0) next
                    found = 1
                    chunk = substr(chunk, at)
                    endh = index(chunk, "</h2>")
                    if (endh == 0) next
                    chunk = substr(chunk, endh + 5)
                }
                endhr = index(chunk, "<hr")
                if (endhr > 0) {
                    printf "%s", substr(chunk, 1, endhr - 1)
                    exit
                }
                printf "%s\n", chunk
            }
        ' "${raw}"
    )"
    [ -n "${html}" ] || return 0
    tmp="$(mktemp)"
    printf '%s' "${html}" > "${tmp}"
    text="$(htmlq -f "${tmp}" -w -t | sed '/^[[:space:]]*$/d' | paste -sd ' ' -)"
    rm -f "${tmp}"
    printf '%s\n' "${text}" | sed 's/[[:space:]][[:space:]]*/ /g; s/^[[:space:]]//; s/[[:space:]]$//'
}
