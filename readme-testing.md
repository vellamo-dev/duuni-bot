# Testing

Duuni-Bot ships with its own smoke test. You do not need a separate test suite: the pipeline is deterministic, every step runs on its own, and each step leaves a visible output file that is itself the assertion.

## Built-in checks

- `bash src/main/bash/check-system.sh` — verifies the environment (Bash 5, required commands, Python packages).
- `bash src/main/bash/check-conf.sh` — prints the effective configuration, so you can confirm paths and overrides before running.

## Running each step separately

The pipeline is seven independent steps. Run them one at a time and check what each produces:

```shell
bash src/main/bash/run.sh -s 1    # listing pages  -> links/listing-pages.tsv
bash src/main/bash/run.sh -s 2    # job addresses  -> links/job-pages.tsv
bash src/main/bash/run.sh -s 3    # raw pages      -> jobs/*/raw.html
bash src/main/bash/run.sh -s 4    # extract        -> jobs/*/meta.json, job-description.txt
bash src/main/bash/run.sh -s 5    # language       -> jobs/*/meta.json (jobLanguage)
bash src/main/bash/run.sh -s 6    # skills keywords
bash src/main/bash/run.sh -s 7    # English keywords
```

The full chain runs all of them:

```shell
bash src/main/bash/duuni-bot.sh
```

For a fast smoke test, cap the number of jobs with `DB_ENV_LIMIT_JOBS`:

```shell
DB_ENV_LIMIT_JOBS=10 bash src/main/bash/duuni-bot.sh
```

This processes only the first 10 jobs instead of the whole feed.

## Container round-trip

The `tools/builds/targets/` folder provides ready-made test runs for both targets:

- **macOS** (Apple's Container CLI): `build-image-macos.sh`, `run-container-macos.sh`, `stop-container-macos.sh`, `uninstall-clean-macos.sh`.
- **Linux** (Podman): `build-image-podman.sh`, `run-container-podman.sh`, `stop-container-podman.sh`, `uninstall-clean-podman.sh`.

A container smoke test is: build the image, run it, execute a step, and check the output under the mounted data directory.

## Validate extracted data

`tools/test/check-extracted-data.sh` checks that an extracted data directory has the expected structure, for both local and container output:

```shell
bash tools/test/check-extracted-data.sh ~/duuni-data
# or rely on DB_ENV_PATH_DATA
DB_ENV_PATH_DATA=~/duuni-data bash tools/test/check-extracted-data.sh
```

It verifies the top-level layout, the link tables, and every job's `meta.json` and `job-description.txt`, and exits `0` when the data looks valid or `1` otherwise.

## Lightweight checks you can add

No heavy framework is needed, but a few cheap checks catch most regressions:

1. **Syntax** — `bash -n` over every script, plus ShellCheck.
2. **Per-step smoke** — run each `-s N` and assert the expected output file appears.
3. **Golden sample** — keep a small snapshot of expected `meta.json` / `job-description.txt` and diff after changes.
4. **Idempotency** — re-run a step and confirm the skip logic does not duplicate or corrupt data.
5. **Error path** — remove a dependency or feed a bad config and confirm a clear error and a non-zero exit.
