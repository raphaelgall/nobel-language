# Tests for database setup and ingestion

library(testthat)
library(DBI)
library(RSQLite)
source("R/utils.R")
source("R/db_setup.R")
source("R/db_queries.R")

test_that("create_database creates schema", {
  tmp <- tempfile(fileext = ".db")
  con <- create_database(tmp)

  # Check tables exist
  tables <- dbListTables(con)
  expect_true("speeches" %in% tables)
  expect_true("speeches_fts" %in% tables)
  expect_true("word_frequencies" %in% tables)
  expect_true("decade_summaries" %in% tables)

  dbDisconnect(con)
  unlink(tmp)
})

test_that("ingest_speeches populates database", {
  lit_dir <- "nobelprizestats/nobelprize_lit/all"
  pea_dir <- "nobelprizestats/nobelprize_pea/all"

  if (!dir.exists(lit_dir)) {
    skip("Speech directories not found (run from project root)")
  }

  tmp <- tempfile(fileext = ".db")
  con <- create_database(tmp)

  lit_count <- ingest_speeches(con, lit_dir, "literature")
  expect_gt(lit_count, 60)

  pea_count <- ingest_speeches(con, pea_dir, "peace")
  expect_gt(pea_count, 60)

  # Verify total
  total <- dbGetQuery(con, "SELECT COUNT(*) as n FROM speeches")$n
  expect_equal(total, lit_count + pea_count)

  # Verify no empty texts
  empty <- dbGetQuery(con, "SELECT COUNT(*) as n FROM speeches WHERE length(trim(text)) = 0")$n
  expect_equal(empty, 0)

  # Verify FTS index is populated
  fts_count <- dbGetQuery(con, "SELECT COUNT(*) as n FROM speeches_fts")$n
  expect_equal(fts_count, total)

  dbDisconnect(con)
  unlink(tmp)
})

cat("All database tests passed!\n")
