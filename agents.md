# AGENTS.md

Duuni-Bot is a small Bash tool that extracts IT job listings from duunitori.fi into plain, ready-to-use files. It is a finished, single-purpose project.

## Read-only

This repository is not regularly maintained and does not accept pull requests. Do not modify the code here. Fork it and adapt it for your own use instead.

## Run

Requirements: Bash 5, plus `curl`, `jq`, `htmlq`, `pandoc`, `python3`, and the Python package `fast-langdetect`.

```shell
bash src/main/bash/duuni-bot.sh     # run all steps
bash src/main/bash/run.sh -s N      # run one step
```

Or run the ready-made container image from quay.io without building:

```shell
bash tools/run/targets/macos/run-quay-macos.sh    # macOS (Apple's Container CLI)
bash tools/run/targets/linux/run-quay-podman.sh   # Linux (Podman)
```

The image is `quay.io/vellamo/duuni-bot:latest`.

## Verify

First, confirm the environment can run the app:

```shell
bash src/main/bash/check-system.sh
```

It checks the operating system, Bash 5, and every required command and Python package, and prints the install commands for anything missing. Run it before the app, and fix what it reports before proceeding.

Then check the configuration and the extracted data:

```shell
bash src/main/bash/check-conf.sh                # effective configuration
bash tools/test/check-extracted-data.sh <dir>   # validate extracted data
```

A fast end-to-end smoke test runs the whole pipeline on a small subset:

```shell
DB_ENV_LIMIT_JOBS=10 bash src/main/bash/duuni-bot.sh
```

## Documentation

- [Usage](./readme-usage.md): how to install and run it.
- [Scope](./readme-scope.md): what the project is and is not.
- [Testing](./readme-testing.md): how to verify it works.
