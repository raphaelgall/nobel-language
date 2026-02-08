# Orchestrator: build everything from scratch
# Run from project root: Rscript build/build_all.R

cat("========================================\n")
cat("  Nobel Speech Explorer - Full Build\n")
cat("========================================\n\n")

start_time <- Sys.time()

# Step 1: Build database
cat("Step 1/3: Building database...\n")
source("build/build_database.R")

# Step 2: Compute word frequencies
cat("\n\nStep 2/3: Computing word frequencies...\n")
source("build/build_word_frequencies.R")

# Step 3: Generate decade summaries (requires API key)
cat("\n\nStep 3/3: Generating decade summaries...\n")
source("build/build_decade_summaries.R")

elapsed <- round(difftime(Sys.time(), start_time, units = "secs"), 1)
cat(sprintf("\n\nBuild completed in %s seconds.\n", elapsed))
cat("You can now run the app with: shiny::runApp()\n")
