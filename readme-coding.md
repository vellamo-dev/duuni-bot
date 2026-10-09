# Coding guide

This document describes how the code is organised and the conventions worth following when you fork, change, or extend Duuni-Bot. It complements [`readme-usage.md`](./readme-usage.md), which explains how to run it.

The project is a Bash 5 pipeline. A few project-specific conventions exist so that paths resolve the same way at run time and inside coding tools, and so the bot can run unattended while leaving useful logs behind.

## Project in brief

Duuni-Bot fetches IT job pages from duunitori.fi and processes them in a fixed chain of seven steps:

1. Collect the listing-page addresses.
2. Collect the job-page addresses from the listings.
3. Download the raw job pages.
4. Extract job metadata and descriptions.
5. Detect the language of each job.
6. Extract skills keywords (a compact dictionary).
7. Extract English technology keywords (a large dictionary, optional and slower).

The entry points are plain Bash scripts. Every step is a separate script, and each step's logic lives in reusable functions under `fn/`.

## Repository layout

```
.
├── Dockerfile                    # multi-stage image (builds htmlq + Python venv)
├── src/main/bash/                # the application root (DUUNI_ROOT)
│   ├── duuni-bot.conf.sh         # central configuration
│   ├── duuni-bot.sh              # runs all steps in order
│   ├── run.sh                    # runs a single step: run.sh -s N
│   ├── s01-…s07-….sh             # the seven step scripts
│   ├── check-system.sh           # environment / dependency check
│   ├── check-conf.sh             # prints the effective configuration
│   ├── entrypoint.sh             # container entry point (writes crontab, runs supercronic)
│   ├── fn/                       # reusable functions, grouped by domain
│   │   ├── conf/                 #   path resolution (paths.sh)
│   │   ├── logging/              #   info/error logging
│   │   ├── progress/             #   terminal output (report.sh)
│   │   ├── clean/                #   data reset/cleanup
│   │   ├── http/                 #   HTTP requests
│   │   ├── html/                 #   htmlq helpers
│   │   ├── listing/              #   listing extraction
│   │   ├── job/                  #   job extraction
│   │   └── meta/                 #   time & stamp helpers
│   └── assets/                   # fasttext model, keyword dictionaries, Python, templates
└── tools/builds/targets/macos/   # macOS container build/run/stop/clean scripts
```

The application root is `src/main/bash` and is exported as `DUUNI_ROOT` by `duuni-bot.conf.sh`.

## Execution flow

- **`duuni-bot.sh`** runs every configured step in order (1..N) from the `DB_RS` array. It is the "run everything" entry point used by the container cron job.
- **`run.sh -s N`** runs a single step. It parses `-s N` plus any extra arguments, resolves the step number to a script through `DB_RS`, and then `exec bash <script>` with the remaining arguments forwarded.
- **Step scripts** (`s01-…s07-….sh`) are thin: they source their dependencies, install the error trap, log the start, call the function that does the work, and log the completion.

Steps are **1-based**: `DB_RS` has an empty placeholder at index 0 so that step 1 maps to `DB_RS[1]`.

## Source loading

All files are sourced **relative to the file that sources them**, never relative to the project root or the current working directory. Every script and function file computes its own directory once and stores it in a `readonly` variable:

```bash
PATH_SCR_X="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_X
```

- `CDPATH=''` avoids surprising `cd` behaviour.
- `cd -P` resolves symlinks so the physical path is used.
- `BASH_SOURCE[0]` is the file itself, so the result is independent of where the command was invoked.

`duuni-bot.conf.sh` sets `DUUNI_ROOT` the same way. Downstream files guard the source of the config so it is only loaded once:

```bash
if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_X}/duuni-bot.conf.sh"
fi
```

Follow this pattern when you add a new script or function file.

## Configuration

All configuration lives in `duuni-bot.conf.sh`. There are three naming families:

| Prefix      | Meaning                                          | Example                |
| ----------- | ------------------------------------------------ | ---------------------- |
| `DB_*`      | Configured value                                | `DB_SLEEP`, `DB_PATH_DATA` |
| `DB_DIR_*`  | Directory name under the data directory          | `DB_DIR_JOBS`          |
| `DB_FILE_*` | File name (data or asset)                       | `DB_FILE_META_JSON`    |
| `DB_PROP_*` | JSON property name written into `meta.json`      | `DB_PROP_JOB_TITLE`    |
| `DB_ENV_*`  | Environment override for a `DB_*` value          | `DB_ENV_DB_SLEEP`      |

- The step list is the `DB_RS` array (`DB_RS[1]` = step 1, and so on).
- Keep JSON property names in `DB_PROP_*` rather than hard-coding strings, so they stay consistent between the extraction and any downstream consumer.
- The end of the config applies optional **`DB_ENV_*` overrides**. An override is applied only when the variable is set and, for the data directory, only when it points to an existing directory. Add new overridable settings here, following the same pattern.

Run `bash src/main/bash/check-conf.sh` to see the effective configuration, including which `DB_ENV_*` variables are present.

## Adding or changing a step

1. Add the script name to `DB_RS` in `duuni-bot.conf.sh`.
2. Create the step script in `src/main/bash/` with this shape:

```bash
#!/usr/bin/env bash
# Step N - short description
set -euo pipefail
set -E

PATH_SCR_SNN="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PATH_SCR_SNN

if [ -z "${DUUNI_ROOT:-}" ]; then
    source "${PATH_SCR_SNN}/duuni-bot.conf.sh"
fi
source "${PATH_SCR_SNN}/fn/<domain>/<file>.sh"
source "${PATH_SCR_SNN}/fn/logging/log.sh"

dbot_trap_errors "Feature name"
dbot_log "Feature name" "Starting …"

# …call the work function(s)…

dbot_log "Feature name" "… completed"
```

3. Put the actual logic in a function under `fn/<domain>/`, and keep the step script as a thin wrapper.

## Function libraries (`fn/`)

Functions are grouped by domain, one directory per domain. A function file:

- computes and `readonly`s its own `PATH_SCR_FN_*` (guarded with `[ -z "${PATH_SCR_FN_*:-}" ]` so it is not recomputed when sourced twice),
- sources its own dependencies relative to itself,
- exposes one or more well-named functions, and returns non-zero on failure instead of calling `exit` (so callers can handle the failure).

Public helpers you will use most often:

- **Paths**: `fn/conf/paths.sh`; `ensure_dir`, `expand_home`, `resolve_path`, `path_of_data_dir`, `path_of_data_item`, `path_of_data_items_dir`.
- **Logging**: `fn/logging/log.sh` (sources both info and error); `dbot_log`, `dbot_error`.
- **Progress**: `fn/progress/report.sh`; `print_step_start`, `print_step_end`, `print_error`, `print_progress`.
- **Time**: `fn/meta/time.sh`; `utc_now`, `epoch_now`, `epoch_to_utc`, `file_created_utc`, `format_duration`.

## Error handling

Every top-level script sets `set -euo pipefail` **and** `set -E` (errtrace), then installs a trap:

```bash
dbot_trap_errors "Feature name"
```

The trap is defined in `fn/logging/log_common.sh`. On an uncaught error it writes a terminating error-log entry and exits 1. `set -E` makes the trap also fire inside functions, which is where most work happens.

Rules of thumb:

- Use `set -euo pipefail` + `set -E` in top-level scripts.
- Don't sprinkle `exit` through functions; return non-zero and let the caller decide.
- When an error must terminate the whole run, rely on the ERR trap (or return non-zero up to the step script).
- A `|| true` (or a guarded fallback) is acceptable where a failure is genuinely non-fatal and must not stop the run.

## Logging

Logging is what lets the bot run unattended and be analysed later. Two functions:

```bash
dbot_log  "Feature" "message"    # INFO
dbot_error "Feature" "message"   # ERROR
```

- Log lines have the form `YYYY-MM-DD HH:MM:SS[,mmm] LEVEL [feature] message`.
- `dbot_timestamp` uses `perl` for millisecond precision and falls back to `date`.
- `dbot_escape` sanitises control characters so each entry stays on one line.
- `dbot_write` ensures the parent directory exists, appends under an exclusive `flock` when available, and falls back to stderr if the file cannot be written. It always returns 0 so logging can never break the run.
- Info files: `<data>/logs/info/<YYYY-MM-DD>.log`; error files: `<data>/logs/errors/<YYYY-MM-DD>.log`.

The paths come from `path_of_log_info_file` / `path_of_log_error_file` in `fn/conf/paths.sh`.

## Progress output

Terminal output is centralised in `fn/progress/report.sh` so it stays consistent:

- `print_step_start "…"`: yellow step banner.
- `print_step_end "…"`: green summary.
- `print_error "…"`: red message to stderr.
- `print_progress <width> <n> <title> [skip|fail]`: padded progress line, with a coloured `[skip]`/`[fail]` mark.

`report.sh` is already sourced by `log.sh`, so the helpers are available wherever logging is.

## Paths and data layout

All data paths resolve through `fn/conf/paths.sh`, never by concatenating strings manually:

- `resolve_path` expands `~/` and resolves relative paths against `DUUNI_ROOT`.
- `path_of_data_dir` returns the data directory (cached in `DU_BOT_PATH_DATA`). A configured data path that lives inside `DUUNI_ROOT` automatically gets a `/data` suffix for local development.
- `path_of_data_item` / `path_of_data_items_dir` resolve a path under the data directory and ensure the parent/directory exists.

The data layout is described in [`readme-usage.md`](./readme-usage.md#output); the directory and file names are all defined in `duuni-bot.conf.sh` (`DB_DIR_*` / `DB_FILE_*`).

## Time and meta helpers

`fn/meta/time.sh` provides the time conversions used across the steps:

- `utc_now`, `epoch_now`, `epoch_to_utc`
- `file_created_utc`: portable file birth time (BSD `stat` on macOS, GNU `stat` elsewhere)
- `format_duration`: whole seconds as `Xm Ys`

## Containerisation

- `Dockerfile` is a two-stage build: a builder compiles `htmlq` (no official arm64 binary) and creates the Python venv with `fast-langdetect`, and a slim runtime copies those in and adds `supercronic`.
- `entrypoint.sh` writes the crontab from `CRON_SCHEDULE` and runs `supercronic` in the foreground.
- The runtime runs as the non-root user `duuni` (UID 10001) and stores data under `/data`.
- The macOS helper scripts in `tools/builds/targets/macos/` build/run/stop/clean the image via Apple's Container CLI; they are macOS-only and check the platform first.

Keep the two stages on the same Debian release so the copied Python venv's `python3.X` path matches at runtime.

## Quick conventions checklist

- Bash 5; `set -euo pipefail` and `set -E` in top-level scripts.
- Source everything relative to the sourcing file (`BASH_SOURCE[0]` + `cd -P` + `pwd -P`).
- Guard `duuni-bot.conf.sh` loading with `[ -z "${DUUNI_ROOT:-}" ]`.
- Configuration values use `DB_*`; JSON property names use `DB_PROP_*`; env overrides use `DB_ENV_*`.
- Steps are 1-based via the `DB_RS` array; keep step scripts thin and put logic in `fn/`.
- Install `dbot_trap_errors "Feature"` once per top-level script.
- Log progress with `dbot_log` / `dbot_error`; print progress with the `report.sh` helpers.
- Resolve all data paths via `fn/conf/paths.sh`, never with manual string concatenation.
- Don't `exit` inside `fn/` functions; return non-zero and let the caller handle it.
