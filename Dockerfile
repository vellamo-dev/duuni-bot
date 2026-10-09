# syntax=docker/dockerfile:1
# Duuni-Bot container: Debian slim + pandoc + supercronic.
# Builds for linux/amd64 and linux/arm64 from the same Dockerfile.

# ---------------------------------------------------------------------------
# Builder: Python packages + htmlq (built from source so arm64 also works).
# Pin to bookworm so the builder's Python (3.11) matches the runtime stage;
# otherwise the copied venv's site-packages path (python3.X) won't resolve.
# ---------------------------------------------------------------------------
FROM rust:1-bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-venv python3-dev \
    && rm -rf /var/lib/apt/lists/*

# htmlq has no official arm64 release binary, so compile it for whichever
# architecture the build targets (amd64 or arm64).
RUN cargo install htmlq --root /opt/htmlq

# Language-detection dependencies in an isolated venv. `fasttext` uses a
# prebuilt wheel on amd64 and compiles from source on arm64 (needs python3-dev).
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/venv/bin/pip install --no-cache-dir fast-langdetect

# ---------------------------------------------------------------------------
# Runtime.
# ---------------------------------------------------------------------------
FROM debian:bookworm-slim

# System dependencies.
RUN apt-get update && apt-get install -y --no-install-recommends \
        bash ca-certificates curl jq pandoc python3 tzdata \
    && rm -rf /var/lib/apt/lists/*

# supercronic - static cron binary, available for amd64 and arm64.
# Detect the architecture at build time so the download works on every builder
# (TARGETARCH is a BuildKit automatic arg and is empty on some builders).
RUN arch="$(dpkg --print-architecture)" \
    && curl -fsSL -o /usr/local/bin/supercronic \
        "https://github.com/aptible/supercronic/releases/download/v0.2.49/supercronic-linux-${arch}" \
    && chmod +x /usr/local/bin/supercronic

# htmlq and the Python venv built in the builder stage.
COPY --from=builder /opt/htmlq/bin/htmlq /usr/local/bin/htmlq
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

# Application scripts, assets, and license.
# src/main/bash is the project directory; install it into /opt/duuni-bot so
# the entry point lives at /opt/duuni-bot/duuni-bot.sh.
COPY src/main/bash /opt/duuni-bot
COPY LICENSE /opt/duuni-bot/LICENSE
# Ensure the non-root user can read every file and traverse every directory,
# regardless of the source files' own permissions.
RUN chmod -R a+rX /opt/duuni-bot

# Run as a non-root user with a fixed UID so volume ownership is predictable.
# Keep the UID in sync with CONTAINER_UID in tools/builds/targets/*/shared/build-run.conf.
RUN groupadd --gid 10001 duuni \
    && useradd --uid 10001 --gid 10001 --home-dir /home/duuni --create-home --shell /usr/sbin/nologin duuni \
    && mkdir -p /data \
    && chown duuni:duuni /data

# Defaults - override at run time with `docker run -e ...`.
# CRON_SCHEDULE is also defined in tools/builds/targets/*/shared/build-run.conf; keep them in sync.
ENV TZ=UTC \
    CRON_SCHEDULE="0 3 * * *" \
    DB_ENV_ENABLE_ST_EK2=0 \
    DB_ENV_PATH_DATA=/data

# Mount the data directory here (and keep it in sync with DB_ENV_PATH_DATA).
# For a bind mount, the host directory must be owned by UID 10001:
#   sudo chown -R 10001:10001 <host-dir>
VOLUME ["/data"]

USER duuni

ENTRYPOINT ["/opt/duuni-bot/entrypoint.sh"]
