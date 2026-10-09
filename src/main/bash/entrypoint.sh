#!/bin/sh
# Duuni-Bot container entrypoint: write the crontab from CRON_SCHEDULE and run
# supercronic in the foreground so the container stays alive forever.

set -eu

SCHEDULE="${CRON_SCHEDULE:-0 3 * * *}"
DATA_DIR="${DB_ENV_PATH_DATA:-/data}"

# Create the data directory (works for named volumes owned by the app user)
# and fail with a clear message when a bind mount is not writable.
mkdir -p "${DATA_DIR}" 2>/dev/null || true
if [ ! -w "${DATA_DIR}" ]; then
    echo "Error: ${DATA_DIR} is not writable by UID $(id -u)." >&2
    echo "For a bind mount, make the host directory writable: chmod -R a+rwX <host-dir>" >&2
    exit 1
fi

# Write an informational log entry for the container start, matching the
# application's own log format (timestamp INFO [feature] message). This is
# best-effort: a log write failure must not prevent the container from starting.
LOG_DIR="${DATA_DIR}/logs/info"
LOG_FILE="${LOG_DIR}/$(date +%Y-%m-%d).log"
if mkdir -p "${LOG_DIR}" 2>/dev/null; then
    printf '%s INFO [Container] Container started (schedule=%s, data=%s)\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" "${SCHEDULE}" "${DATA_DIR}" >> "${LOG_FILE}" 2>/dev/null || true
else
    echo "Warning: cannot create log directory '${LOG_DIR}'; skipping container-start log." >&2
fi

printf '%s cd /opt/duuni-bot && bash duuni-bot.sh\n' "${SCHEDULE}" > /home/duuni/crontab

echo "Duuni-Bot: schedule=${SCHEDULE} data=${DATA_DIR}"

exec supercronic /home/duuni/crontab
