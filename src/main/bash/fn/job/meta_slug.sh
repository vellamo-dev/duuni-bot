#!/usr/bin/env bash
# Job slug parsing helpers.

# Return the numeric id at the end of a job slug.
job_slug_id() {
    printf '%s\n' "${1}" | sed -n 's/.*-\([0-9][0-9]*\)$/\1/p'
}

# Return the group tag before the numeric id, such as sdsuu.
job_slug_group() {
    printf '%s\n' "${1}" | sed -n 's/.*-\([a-z][a-z]*\)-[0-9][0-9]*$/\1/p'
}
