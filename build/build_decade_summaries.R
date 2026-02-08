# Generate decade summaries using Claude API
# Run from project root: Rscript build/build_decade_summaries.R
# Requires ANTHROPIC_API_KEY in .Renviron

cat("=== Generating Decade Summaries ===\n\n")

source("R/utils.R")
source("R/db_setup.R")
source("R/db_queries.R")
source("R/claude_api.R")

db_path <- "data/nobel_speeches.db"

if (!file.exists(db_path)) {
  stop("Database not found at ", db_path, ". Run build_database.R and build_word_frequencies.R first.")
}

# Check API key
api_key <- Sys.getenv("ANTHROPIC_API_KEY")
if (api_key == "") {
  cat("WARNING: ANTHROPIC_API_KEY not set. Skipping summary generation.\n")
  cat("Set it in .Renviron and re-run this script.\n")
  quit(status = 0)
}

con <- dbConnect(RSQLite::SQLite(), db_path)

# Get all decade-category combinations
decades <- get_decades(con)
categories <- c("literature", "peace")

cat(sprintf("Generating summaries for %d decades x %d categories = %d combos\n\n",
            length(decades), length(categories), length(decades) * length(categories)))

for (decade in decades) {
  for (category in categories) {
    # Check if already generated
    existing <- dbGetQuery(con, "
      SELECT COUNT(*) as n FROM decade_summaries
      WHERE decade = ? AND category = ?
    ", params = list(decade, category))$n

    if (existing > 0) {
      cat(sprintf("  %s %s: already exists, skipping\n", decade, category))
      next
    }

    cat(sprintf("  %s %s: generating... ", decade, category))
    tryCatch({
      summary <- generate_decade_summary(con, decade, category)

      dbExecute(con, "
        INSERT OR REPLACE INTO decade_summaries (decade, category, summary_text, generated_at)
        VALUES (?, ?, ?, ?)
      ", params = list(decade, category, summary, format(Sys.time(), "%Y-%m-%d %H:%M:%S")))

      cat(sprintf("OK (%d chars)\n", nchar(summary)))
    }, error = function(e) {
      cat(sprintf("ERROR: %s\n", e$message))
    })

    Sys.sleep(1)  # Rate limit
  }
}

# Verify
stored <- dbGetQuery(con, "SELECT COUNT(*) as n FROM decade_summaries")$n
cat(sprintf("\nTotal summaries stored: %d\n", stored))

dbDisconnect(con)
cat("Done.\n")
