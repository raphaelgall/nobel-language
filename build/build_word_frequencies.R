# Compute word frequencies and store in the database
# Run from project root: Rscript build/build_word_frequencies.R

cat("=== Building Word Frequencies ===\n\n")

source("R/utils.R")
source("R/db_setup.R")
source("R/db_queries.R")
source("R/text_processing.R")

db_path <- "data/nobel_speeches.db"

if (!file.exists(db_path)) {
  stop("Database not found at ", db_path, ". Run build_database.R first.")
}

con <- dbConnect(RSQLite::SQLite(), db_path)

cat("Computing word frequencies (this may take a moment)...\n")
freq_df <- compute_word_frequencies(con, use_stemming = FALSE)
cat(sprintf("  Computed %d word-decade-category combinations\n", nrow(freq_df)))

cat("Storing in database...\n")
store_word_frequencies(con, freq_df)

# Verify
stored <- dbGetQuery(con, "SELECT COUNT(*) as n FROM word_frequencies")$n
cat(sprintf("  Stored %d entries\n", stored))

# Show top words per category
cat("\nTop 10 words (literature):\n")
top_lit <- dbGetQuery(con, "
  SELECT word, SUM(frequency) as total
  FROM word_frequencies WHERE category = 'literature'
  GROUP BY word ORDER BY total DESC LIMIT 10
")
for (i in seq_len(nrow(top_lit))) {
  cat(sprintf("  %s: %d\n", top_lit$word[i], top_lit$total[i]))
}

cat("\nTop 10 words (peace):\n")
top_pea <- dbGetQuery(con, "
  SELECT word, SUM(frequency) as total
  FROM word_frequencies WHERE category = 'peace'
  GROUP BY word ORDER BY total DESC LIMIT 10
")
for (i in seq_len(nrow(top_pea))) {
  cat(sprintf("  %s: %d\n", top_pea$word[i], top_pea$total[i]))
}

dbDisconnect(con)
cat("\nWord frequencies built successfully.\n")
