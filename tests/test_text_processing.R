# Tests for text processing pipeline

library(testthat)
library(DBI)
library(RSQLite)
source("R/utils.R")
source("R/db_setup.R")
source("R/db_queries.R")
source("R/text_processing.R")

test_that("compute_word_frequencies returns expected structure", {
  # Create a test database with a few mock speeches
  tmp <- tempfile(fileext = ".db")
  con <- create_database(tmp)

  dbExecute(con, "
    INSERT INTO speeches (year, author, category, text, decade, filename)
    VALUES (1950, 'Test Author', 'literature', 'The quick brown fox jumps over the lazy dog repeatedly jumping over the fence', '1950s', 'test_1950.txt')
  ")
  dbExecute(con, "
    INSERT INTO speeches (year, author, category, text, decade, filename)
    VALUES (1960, 'Another Author', 'peace', 'Peace and freedom require courage and determination to overcome conflict', '1960s', 'test_1960.txt')
  ")

  freq <- compute_word_frequencies(con, use_stemming = FALSE)

  expect_true(is.data.frame(freq))
  expect_true("word" %in% names(freq))
  expect_true("decade" %in% names(freq))
  expect_true("category" %in% names(freq))
  expect_true("frequency" %in% names(freq))
  expect_true("tf_idf" %in% names(freq))
  expect_gt(nrow(freq), 0)

  dbDisconnect(con)
  unlink(tmp)
})

test_that("read_speech_file handles UTF-8 text", {
  tmp <- tempfile(fileext = ".txt")
  writeLines("This is a test with smart quotes \u201c and \u201d", tmp)
  text <- read_speech_file(tmp)
  expect_true(nchar(text) > 0)
  # Smart quotes should be normalized
  expect_false(grepl("\u201c", text))
  unlink(tmp)
})

cat("All text processing tests passed!\n")
