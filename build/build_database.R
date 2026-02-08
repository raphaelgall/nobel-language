# Build the SQLite database from speech text files
# Run from project root: Rscript build/build_database.R

cat("=== Building Nobel Speeches Database ===\n\n")

# Source utilities
source("R/utils.R")
source("R/db_setup.R")

db_path <- "data/nobel_speeches.db"
lit_dir <- "nobelprizestats/nobelprize_lit/all"
pea_dir <- "nobelprizestats/nobelprize_pea/all"

# Create database with schema
cat("Creating database schema...\n")
con <- create_database(db_path)

# Ingest literature speeches
cat("\nIngesting literature speeches...\n")
lit_count <- ingest_speeches(con, lit_dir, "literature")
cat(sprintf("  Ingested %d literature speeches\n", lit_count))

# Ingest peace speeches
cat("\nIngesting peace speeches...\n")
pea_count <- ingest_speeches(con, pea_dir, "peace")
cat(sprintf("  Ingested %d peace speeches\n", pea_count))

# Verify
cat("\n=== Verification ===\n")
total <- dbGetQuery(con, "SELECT COUNT(*) as n FROM speeches")$n
cat(sprintf("Total speeches in database: %d\n", total))

by_cat <- dbGetQuery(con, "SELECT category, COUNT(*) as n FROM speeches GROUP BY category")
for (i in seq_len(nrow(by_cat))) {
  cat(sprintf("  %s: %d\n", by_cat$category[i], by_cat$n[i]))
}

by_decade <- dbGetQuery(con, "
  SELECT decade, category, COUNT(*) as n
  FROM speeches
  GROUP BY decade, category
  ORDER BY decade, category
")
cat("\nBy decade:\n")
for (i in seq_len(nrow(by_decade))) {
  cat(sprintf("  %s %s: %d\n", by_decade$decade[i], by_decade$category[i], by_decade$n[i]))
}

# Check for empty texts
empty <- dbGetQuery(con, "SELECT COUNT(*) as n FROM speeches WHERE length(trim(text)) = 0")$n
if (empty > 0) {
  cat(sprintf("\nWARNING: %d speeches have empty text!\n", empty))
} else {
  cat("\nAll speeches have non-empty text.\n")
}

# Verify FTS index
fts_count <- dbGetQuery(con, "SELECT COUNT(*) as n FROM speeches_fts")$n
cat(sprintf("FTS index entries: %d\n", fts_count))

dbDisconnect(con)
cat("\nDatabase built successfully at: ", db_path, "\n")
