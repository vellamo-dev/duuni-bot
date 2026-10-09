# Scope of Project

Every project should have a well-defined scope. It keeps the work honest: everyone can see what the project set out to do, and the work itself does not grow until it is no longer manageable.

This project began with a simple goal: to test and prove a few ideas about data extraction. The deeper idea behind it is small and friendly: the tools you choose should be a decision, not a default. In IT it is easy to reach for a technology because everyone else uses it, or because it is fashionable right now. That is not wrong; it is just worth a second look. The aim here is to show that data extraction has a surprisingly light option too, and that measuring the real footprint before choosing is usually worth the effort.

## Primary goal

Show how to build a reliable, standalone, container-based data-extraction application that prepares and stores data in files (not in a database), keeps every downloaded and intermediate file alongside the final output, and shares the result through a shared volume, so other tools can import whichever form of the data they need.

## Lean engineering

This is the part that makes people stop and look twice: the whole pipeline is **Bash plus a handful of small command-line tools**, chained together the classic Unix way: each tool does one thing well, and the pipe between them does the rest. There is no Python service, no Go binary, no Node server, no JVM, no database, no cloud; just the shell that is already on every Unix machine, doing the work one small step at a time.

That is not a limitation. It is the point.

At its heart, this project proves that modern data pipelines can still be built effectively on the fundamental Unix philosophy: **chain small, specialised tools together instead of reaching for a framework.** The result is a container that starts in moments, uses a few megabytes of memory, and costs almost nothing to run, compared with standing up a service, a scheduler, and a database just to move the same files. The smallest tool that does the job is usually enough, and once you try it, it is also the easiest to understand, change, and hand over.

Python appears only once, for language detection, tucked away in its own tiny virtual environment. That is the exception that proves the rule: reach for a heavier tool only when a task genuinely needs it, and keep it isolated.

## Objectives

- Process everything locally, with no network latency, rate limits, or vendor lock-in.
- Keep every downloaded and extracted file, from the raw page to the final keywords, so a further processor can use whichever form it needs.
- Extract a limited amount of HTML content from a website and store it for future processing.
- Process the downloaded data by separating the valuable parts from it.
- Extract the important HTML content from unnecessary content and store it in a reusable form.
- Convert the important content into plain text for easier use later.
- Determine the language of the data.
- Extract important metadata in a reusable form:
  - job title, employer, location
  - publication and expiry dates
  - canonical URL and identifiers
- Extract technology keywords and their categories from the job description.

## What this project is

- A small, single-purpose extractor for one website and one job segment.
- A proof of concept: a reliable, standalone, containerised tool that stores plain files.
- Deterministic and versionable: the same input produces the same output.
- A data pre-processor: its output is meant to be consumed later by a database, a search index, or an AI tool.
- Limited to two container runtimes: **Podman** (Linux) and **Apple's Container CLI** (macOS). This is a deliberate decision, not an omission.

The runtime choice is a project decision, not a limit on forks. The image is a standard OCI image and the code is OS-independent inside a container, so anyone who prefers Docker or another runtime is free to use it.

## What this project is not

These boundaries are not shortcomings; they are what keep the project small, honest, and easy to maintain.

- Not a general-purpose scraping framework. It parses one site's current structure; there is no plug-in model. Scraping is inherently fragile, so updates are expected whenever the site changes.
- Not an ETL platform or orchestrator. No DAG, scheduler UI, retry engine, or job queue; one cron schedule is the whole scheduler.
- Not a database, search engine, or analytics system. Files are the storage.
- Not a web service. No UI, API, or dashboard.
- Not a multi-source system. One website, one segment.
- Not a tool for logins, CAPTCHAs, or anti-bot measures.
- Not an AI or LLM pipeline. Language detection is a statistical model, and keywords come from static dictionaries.
- Not a monitored or maintained service. Logs only; the source site may change and break it.

## Guiding principles

1. **Minimal infrastructure: lean engineering first.** If a cron expression and a container can do the job, that is the whole job.
2. **Files, not a database.** The tool stores files; other tools own persistence and search.
3. **Determinism over cleverness.** A fixed version that can be tested and rolled back beats an adaptive model.
4. **Fork and adapt.** This is a template for other extractors, not a universal product.
5. **Respect the source.** Sleep between downloads, follow the site's rules, and handle personal data responsibly.
6. **Keep everything.** The raw pages, the cleaned HTML, the plain text, the metadata, and the keywords all stay on disk, so later tools can pick whichever form they need.

## When it is done

The project meets its scope when it:

- runs unattended from a container on a schedule,
- stores extracted data as plain files on a shared volume,
- lets another tool import the data without any further scraping,
- keeps each step visible, logged, and re-runnable.

Features beyond this list are out of scope by this agreement.
