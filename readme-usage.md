# How to use

Duuni-Bot extracts IT job listings from duunitori.fi. Run it locally, or build and run it as a container.

## Quick Start

### Run locally

1. Install the dependencies:

   **macOS (Homebrew)**
   ```shell
   brew install bash curl jq pandoc htmlq python3
   python3 -m pip install --user fast-langdetect
   ```

   **Linux (Debian / Ubuntu)**
   ```shell
   sudo apt-get install bash curl jq pandoc python3 python3-pip
   cargo install htmlq
   python3 -m pip install --user fast-langdetect
   ```

2. Run all steps:
   ```shell
   bash src/main/bash/duuni-bot.sh
   ```

### Run in a container

**macOS (Apple's Container CLI)**
```shell
bash tools/builds/targets/macos/build-image-macos.sh
bash tools/builds/targets/macos/run-container-macos.sh
container exec duuni-bot bash /opt/duuni-bot/duuni-bot.sh
```

**Linux (Podman)**
```shell
podman build -t duuni-bot:local .
podman run -d --name duuni-bot -v ~/duuni-data:/data duuni-bot:local
podman exec duuni-bot bash /opt/duuni-bot/duuni-bot.sh
```

---

## Detailed Instructions

### A. Run locally

This is the easiest way to quickly test or run the bot manually. This requires that the environment meets certain criteria. The application includes a script that checks the system for compatibility.

We assume that commands are executed from the root directory of the project.

#### Installing

Duuni-Bot runs on macOS or Linux and requires the following components:

- Bash 5 or newer
- `curl`, `jq`, `htmlq`, `pandoc`, `python3`
- Python package `fast-langdetect`
- The bundled FastText language model (`src/main/bash/assets/fasttext/lid.176.ftz`)

**macOS (Homebrew)**:

```shell
brew install bash curl jq pandoc htmlq python3
python3 -m pip install --user fast-langdetect
```

**Linux (Debian / Ubuntu)**:

```shell
sudo apt-get install bash curl jq pandoc python3 python3-pip
cargo install htmlq
python3 -m pip install --user fast-langdetect
```

**Linux (Fedora / RHEL)**:

```shell
sudo dnf install bash curl jq pandoc python3 python3-pip
cargo install htmlq
python3 -m pip install --user fast-langdetect
```

`htmlq` can also be installed from a release binary instead of `cargo`; see the [htmlq releases](https://github.com/mgdm/htmlq/releases).

#### Environment test

Ensure first that Duuni-Bot can be executed in your environment:

```shell
bash src/main/bash/check-system.sh
```

The script reports which components are present and which are missing, and prints the install commands for your operating system.

To inspect the effective configuration (all `DB_*` values and the environment overrides):

```shell
bash src/main/bash/check-conf.sh
```

#### Configuration

The defaults in `duuni-bot.conf.sh` can be overridden with environment variables, without editing the file.

| Environment variable            | Overrides                   | Purpose                                   |
|---------------------------------|-----------------------------|-------------------------------------------|
| `DB_ENV_PATH_DATA`              | `DB_PATH_DATA`              | Data directory (must be an existing directory) |
| `DB_ENV_ENABLE_ST_EK2`          | `DB_ENABLE_ST_EK2`          | Run (`1`) or skip (`0`) step 7            |
| `DB_ENV_DB_SLEEP`               | `DB_SLEEP`                  | Sleep between downloads (seconds)         |
| `DB_ENV_DB_BROWSER`             | `DB_BROWSER`                | Browser user-agent header                 |
| `DB_ENV_LOG_RETENTION_DAYS`     | `DB_LOG_RETENTION_DAYS`     | Keep logs for this many days              |
| `DB_ENV_REMOVED_RETENTION_DAYS` | `DB_REMOVED_RETENTION_DAYS` | Keep removed jobs for this many days      |
| `DB_ENV_LIMIT_JOBS`             | `DB_LIMIT_JOBS`             | Cap the number of jobs (empty = no limit) |

`DB_PATH_DATA` defaults to a development-time path (`/working/data`). For real use, set `DB_ENV_PATH_DATA` to your own directory, or edit `DB_PATH_DATA`.

To test with a small subset, cap the number of jobs with `DB_ENV_LIMIT_JOBS`:

```shell
DB_ENV_LIMIT_JOBS=10 bash src/main/bash/duuni-bot.sh
```

Set a variable for a single command:

```shell
DB_ENV_DB_SLEEP=10 bash src/main/bash/duuni-bot.sh
```

Or export it first. This works the same on macOS and Linux:

```shell
export DB_ENV_DB_SLEEP=10
export DB_ENV_ENABLE_ST_EK2=1
bash src/main/bash/duuni-bot.sh
```

To keep a setting permanently, add the `export` line to your shell profile:
`~/.zshrc` on macOS (Zsh) or `~/.bashrc` on Linux (Bash).

#### Usage

You can run either the fully automated execution chain or each step separately. There are 7 steps currently.

To run all steps automatically:

```shell
bash src/main/bash/duuni-bot.sh
```

To reset all data (keeping the logs) before the automatic run:

```shell
bash src/main/bash/duuni-bot.sh --reset-all-data
```

To see usage instructions on the terminal, run:

```shell
bash src/main/bash/run.sh
```

##### 1. Step

This step extracts the IT job listing pages from the site and prepares them for the next step.

```shell
bash src/main/bash/run.sh -s 1
```

You can reset all data in this step as well. All data and logs will be erased.

```shell
bash src/main/bash/run.sh -s 1 --reset-data
```

##### 2. Step

This step extracts the list of job addresses from the previously determined listing pages.

```shell
bash src/main/bash/run.sh -s 2
```

##### 3. Step

This step extracts raw job data from the site based on the previously detected listings. Execution of this step takes some time. The sleep time between downloads is determined by the configuration `DB_SLEEP`. The default value is 0.8 seconds. This is crucial to avoid denial of service. If you use this bot regularly, it is recommended to increase this value to 3 seconds.

```shell
bash src/main/bash/run.sh -s 3
```

It also supports cleaning, so that previously downloaded and extracted data is purged.

```shell
bash src/main/bash/run.sh -s 3 --clean-first
```

##### 4. Step

This step reads each downloaded `raw.html` and extracts the job metadata, the job description HTML, and a plain-text version of the offer.

```shell
bash src/main/bash/run.sh -s 4
```

It also supports cleaning previously extracted data:

```shell
bash src/main/bash/run.sh -s 4 --clean-first
```

##### 5. Step

This step detects the language of each job offer and stores it in `meta.json`.

```shell
bash src/main/bash/run.sh -s 5
```

##### 6. Step

This step scans each `job-description.txt` against the skills dictionary and writes the skills keywords and their categories.

```shell
bash src/main/bash/run.sh -s 6
```

To ignore a previous detection and rewrite the keywords:

```shell
bash src/main/bash/run.sh -s 6 --reset
```

##### 7. Step

This step scans each `job-description.txt` against the larger English technology dictionary and writes the English keywords and their categories.

```shell
bash src/main/bash/run.sh -s 7
```

To ignore a previous detection and rewrite the keywords:

```shell
bash src/main/bash/run.sh -s 7 --reset
```

#### Output

Extracted data is stored under the configured data directory (set with `DB_PATH_DATA` in `duuni-bot.conf.sh`, overridable via `DB_ENV_PATH_DATA`). Each job gets its own directory:

```
jobs/<slug>/
  raw.html                           # the original job page (step 3)
  meta.json                          # job metadata (steps 4-7)
  job-data.html                      # the extracted job description block
  job-description.html               # the extracted description
  job-description.txt                # plain-text description
  job-keywords.txt                   # English technology keywords (step 7)
  job-keyword-categories.tsv         # keyword categories (step 7)
  job-keywords-deep.txt              # skills keywords (step 6)
  job-keyword-categories-deep.tsv    # skills categories (step 6)
jobs-removed/                        # jobs marked as removed
links/
  listing-pages.tsv                  # listing page addresses (step 1)
  job-pages.tsv                      # job addresses (step 2)
lists/                               # saved listing pages (step 2)
logs/
  info/                              # informational log
  errors/                            # error log
```

The data directory can be changed with the `DB_PATH_DATA` setting in `duuni-bot.conf.sh`.

To check that an extracted data directory is complete and valid, run:

```shell
bash tools/test/check-extracted-data.sh <data-dir>
```

See [Testing](./readme-testing.md) for details.

### B. From container

The bot can also be run as a container. This is the most suitable option if you want to run it autonomously and do not want to take care of the environment preparations.

#### How to build image

##### Build on macOS (Apple's Container CLI)

On an Apple silicon Mac (macOS 26 or newer), build the image with Apple's Container CLI using the included script:

```shell
bash tools/builds/targets/macos/build-image-macos.sh
```

The script checks the environment, installs Apple's Container CLI if it is missing, and builds the image tagged `duuni-bot:local`.

##### Build with Podman

On Linux (or macOS with Podman):

```shell
podman build -t duuni-bot:local .
```

#### Manage the container on macOS

The macOS scripts live in `tools/builds/targets/macos/` and share their settings in `shared/build-run.conf`. They honor the `DB_ENV_PATH_DATA` environment variable for the data directory.

| Script                     | What it does                              |
| -------------------------- | ----------------------------------------- |
| `build-image-macos.sh`     | Builds the image                          |
| `run-container-macos.sh`   | Creates and starts the container          |
| `stop-container-macos.sh`  | Stops the container                       |
| `uninstall-clean-macos.sh` | Stops the container and removes the image |

```shell
bash tools/builds/targets/macos/build-image-macos.sh
bash tools/builds/targets/macos/run-container-macos.sh
bash tools/builds/targets/macos/stop-container-macos.sh
bash tools/builds/targets/macos/uninstall-clean-macos.sh
```

#### Run the container

The container is configured with environment variables:

| Environment variable   | Purpose                                     |
| ---------------------- | ------------------------------------------- |
| `DB_ENV_PATH_DATA`     | Data directory (must be an existing directory) |
| `DB_ENV_ENABLE_ST_EK2` | Run (`1`) or skip (`0`) step 7              |
| `DB_ENV_DB_SLEEP`      | Sleep between downloads (seconds)           |
| `DB_ENV_DB_BROWSER`    | Browser user-agent header                   |
| `CRON_SCHEDULE`        | Cron schedule (default `0 3 * * *`)        |

The image runs as a non-root user by default. On macOS, Apple's Container CLI maps bind mounts to root, so the container is started as root (`--user root`) to write to the mounted data directory:

```shell
mkdir -p ~/duuni-data
```

On Linux with Podman, the container runs as the non-root user (UID 10001); make the directory writable by that user first:

```shell
mkdir -p ~/duuni-data
sudo chown -R 10001:10001 ~/duuni-data
```

On macOS, use the run script:

```shell
bash tools/builds/targets/macos/run-container-macos.sh
```

Or manually with Apple's Container CLI:

```shell
container create --name duuni-bot \
  --user root \
  --volume ~/duuni-data:/data \
  --env CRON_SCHEDULE='0 3 * * *' \
  --env DB_ENV_DB_SLEEP=10 \
  duuni-bot:local

container start duuni-bot
```

With Podman:

```shell
podman run -d --name duuni-bot \
  -v ~/duuni-data:/data \
  -e CRON_SCHEDULE='0 3 * * *' \
  -e DB_ENV_DB_SLEEP=10 \
  duuni-bot:local
```

Follow the logs with `container logs -f duuni-bot` (or `podman logs -f duuni-bot`).

#### Run manually using the container

Run a step directly from your terminal; there is no need to enter the container.

##### macOS (Apple's Container CLI)

To run bot:

```shell
container exec duuni-bot bash /opt/duuni-bot/duuni-bot.sh
```

To run directly some steps:

```shell
container exec duuni-bot bash /opt/duuni-bot/run.sh -s 1    # step 1: extract listing pages
container exec duuni-bot bash /opt/duuni-bot/run.sh -s 2    # step 2: extract job addresses
container exec duuni-bot bash /opt/duuni-bot/run.sh -s 3    # step 3: download raw job pages
container exec duuni-bot bash /opt/duuni-bot/run.sh -s 4    # step 4: extract job data
container exec duuni-bot bash /opt/duuni-bot/run.sh -s 5    # step 5: detect language
container exec duuni-bot bash /opt/duuni-bot/run.sh -s 6    # step 6: skills keywords
container exec duuni-bot bash /opt/duuni-bot/run.sh -s 7    # step 7: English keywords
```

##### Podman (Linux)

Podman commands are very similar to Apple's Container CLI.

To run bot:

```shell
podman exec duuni-bot bash /opt/duuni-bot/duuni-bot.sh
```

To run directly some steps:

```shell
podman exec duuni-bot bash /opt/duuni-bot/run.sh -s 1
```

##### Additional operations

Append a flag to run a step with an option:

- `--reset-data` (step 1): reset all data and logs
- `--clean-first` (steps 3 and 4): purge previously downloaded/extracted data
- `--reset` (steps 6 and 7): rewrite keywords

For example:

```shell
container exec duuni-bot bash /opt/duuni-bot/run.sh -s 1 --reset-data
container exec duuni-bot bash /opt/duuni-bot/run.sh -s 7 --reset
```
