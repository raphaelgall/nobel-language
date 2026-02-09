# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Nobel Prize Speech Explorer** — An R Shiny web app for interactively exploring Nobel Prize speeches (Literature & Peace, 1940s–2025). Built on a corpus of 149 speeches with full-text search, word frequency analysis, decade trend summaries, and Claude-powered Q&A.

Originally inspired by [nobelprizestats](https://github.com/raphaelgall/nobelprizestats) (2016), modernized with Shiny, tidytext, SQLite, and the Claude API.

## Tech Stack

- **UI:** R Shiny + bslib (Bootstrap 5, `flatly` theme)
- **Data:** SQLite with FTS5 for full-text search
- **Text processing:** tidytext + SnowballC
- **Charts:** plotly + ggplot2
- **LLM:** Claude API via httr2
- **Tables:** DT package

## Key Directories

- `R/` — Core R functions (utils, DB setup/queries, text processing, Claude API)
- `modules/` — Shiny modules (one per tab: browser, search, word freq, trends, chat)
- `build/` — Build scripts (database ingestion, word frequencies, decade summaries)
- `data/` — Generated SQLite database (not committed)
- `www/` — Static assets (CSS)
- `tests/` — Unit tests (testthat)
- `nobelprizestats/` — Cloned speech corpus (read-only data source)

## Build / Test Commands

```bash
# Build everything (database + word frequencies + summaries)
Rscript build/build_all.R

# Build individual steps
Rscript build/build_database.R
Rscript build/build_word_frequencies.R
Rscript build/build_decade_summaries.R  # requires ANTHROPIC_API_KEY

# Run tests
Rscript tests/test_filename_parsing.R
Rscript tests/test_db_setup.R
Rscript tests/test_text_processing.R

# Run the app
Rscript -e "shiny::runApp()"
```

## Important Files

- `app.R` — Main Shiny entry point
- `.Renviron` — API keys (not committed); needs `ANTHROPIC_API_KEY=sk-...`
- `data/nobel_speeches.db` — Generated SQLite database (not committed)

## Architecture

- **Shiny modules pattern**: each tab is a separate module file in `modules/`
- **Shared DB connection**: opened once in `server()`, passed to all modules
- **Pre-computed data**: word frequencies and decade summaries stored in SQLite for instant queries
- **FTS5 search**: full-text search with snippet extraction and ranking

## Outstanding Items

- **Decade summaries not generated**: The "Decade Trends" tab and "Ask Claude" chat require an Anthropic API key (`ANTHROPIC_API_KEY`). This is separate from the Claude Max plan — sign up at https://console.anthropic.com, add billing, create a key, and add `ANTHROPIC_API_KEY=sk-ant-...` to `.Renviron`. Then run `Rscript build/build_decade_summaries.R`.
- **Han Kang 2024 lecture**: Not yet published on nobelprize.org (returns 404). Re-run `build/download_missing_speeches.R` once available.

## Additional Documentation

Check these files when working on relevant topics:

- `.claude/docs/architectural_patterns.md` — Architectural patterns, design decisions, and conventions
