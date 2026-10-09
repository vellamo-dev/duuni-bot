# Duuni-Bot

Duuni-Bot is a small bash tool that extracts IT job listings from duunitori.fi and turns them into clean, ready-to-use files. It started as a playground for bash scripting ideas, grew into a genuinely useful tool, and is now shared for anyone to use, fork, and adapt.

It is a pre-processing step, not an end product. The fun begins when you feed the extracted files into a database, a search index, or an AI tool.

## What it does

One run takes you from raw web pages to tidy files:

- Finds all IT job pages on duunitori.fi.
- Downloads those pages.
- Extracts the useful parts into clean formats:
  - job metadata (title, employer, location, dates, URL),
  - a plain-text version of each job description,
  - technology keywords and their categories.
- Stores everything as plain files, ready for automation.

## Quick start

The fastest path. Every option is explained in [Usage](./readme-usage.md).

**Run locally**

```shell
# 1. Install the dependencies
brew install bash curl jq pandoc htmlq python3    # macOS
python3 -m pip install --user fast-langdetect

# 2. Run everything
bash src/main/bash/duuni-bot.sh
```

**Run in a container (macOS)**

```shell
bash tools/builds/targets/macos/build-image-macos.sh
bash tools/builds/targets/macos/run-container-macos.sh
container exec duuni-bot bash /opt/duuni-bot/duuni-bot.sh
```

## Documentation

- [Usage](./readme-usage.md): how to install and run the bot locally or in a container.
- [Scope](./readme-scope.md): what the project is and is not, and its intentional boundaries.
- [Coding](./readme-coding.md): how the code is organised and the conventions for contributors.
- [Testing](./readme-testing.md): how to verify the app works, since it ships with its own smoke test.

## The idea behind it

Duuni-Bot is a proof of concept for **lean engineering**. The question it asks is simple: how little do you actually need to extract and prepare data?

The answer, it turns out, is "surprisingly little". A shell, a few small command-line tools, and a cron schedule can do the whole job, on any machine that runs containers, or none at all.

That is not a statement against bigger tools. ETL platforms and orchestrators are genuinely useful, and there are many situations where they are exactly the right choice. The point here is only that the choice should be deliberate, not a default.

The gentle nudge behind this project: before reaching for a platform or a framework, ask what the smallest honest solution looks like. If a cron expression and a container can do the job, that may be all you need, and it is usually the easiest thing to understand, change, and hand over.

The same kind of containerised app can be built, deployed automatically, and pointed at other sources.

## Where AI fits

A fair question: why not let an AI do the whole job?

AI is a wonderful tool, and this project is not "bash versus AI". The two are strong at different things and fit together nicely:

- A script is deterministic: the same input gives the same output, every run. That makes it easy to test and to roll back.
- A script fails loudly, so a broken page shows up instead of being silently wrong.
- A script keeps personal data on your own machine, so nothing is sent to a third-party model on every run.
- A script is a fixed version you can keep in version control, like any other software.

AI shines on the other side of the pipeline: searching, summarising, and reasoning over the data this script has already extracted. That is where it adds the most value with the least risk.

So the two are friends here, not rivals: a small deterministic script does the careful extraction, and an AI does the understanding afterwards, on clean, ready-to-use data.

## Who this is useful for

Duuni-Bot works as a proof of concept that can be adapted to other data-extraction tasks. It is also useful for anyone who wants to analyse the IT job market in Finland, or who is looking for a job, because it hands over data that is already clean and ready for further processing.

## Caveats

Websites change constantly, so there is no guarantee that data can still be extracted in the way this project does it. If the site changes, the scripts need an update. This project is not maintained continuously. If that happens, fork it and adjust it.

## Restrictions on data usage

There are no legal restrictions on the tools users can use to collect data from the internet or on how they process that data for their own purposes. Whether data is published as HTML or another format, the delivery method does not mandate browser-only consumption or, by itself, impose legal restrictions on the tools users may use. Subject to applicable law and terms of service, users may employ bots, AI tools, or other utilities to collect and process such data for their own purposes, even from primitive or inconvenient formats, into systematic, distraction-free, end-user-friendly output.

The job advertisements extracted with this utility are published for a public audience. The intended use of this utility is reading and extracting them for market research, personal use, scientific purposes, and similar non-commercial use. It is not for any commercial purpose. You shall not use this utility to sell the extracted data.

Publication is not a licence to republish the material. Fair dealing and the applicable exceptions still apply. See the `duunitori.fi` rules on use of content before any further use of the extracted data.

The user of this utility or project shall not use the extracted data to create or offer a competing or substantially similar service, or otherwise commercially exploit the data, including by systematically linking to or embedding the content in another service or product made available to third parties.

Job advertisements can contain personal data: names, emails, phone numbers, sometimes more. A non-commercial or scientific framing does not automatically exempt that processing from the GDPR. It is the user's responsibility to follow the applicable regulations.

This utility does not give you any new rights over the original data. It is only a tool for grabbing and processing it.

## Licensing

Please see the [LICENSE](./LICENSE) document for usage rights (*CC BY-NC-SA 4.0*).
