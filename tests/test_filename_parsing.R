# Tests for filename parsing

library(testthat)
source("R/utils.R")

test_that("parse_speech_filename handles simple names", {
  result <- parse_speech_filename("Faulkner_1949.txt")
  expect_equal(result$author, "Faulkner")
  expect_equal(result$year, 1949)
  expect_equal(result$decade, "1940s")
  expect_equal(result$filename, "Faulkner_1949.txt")
})

test_that("parse_speech_filename handles hyphenated names", {
  result <- parse_speech_filename("Mandela-and-deKlerk_1993.txt")
  expect_equal(result$author, "Mandela and deKlerk")
  expect_equal(result$year, 1993)
  expect_equal(result$decade, "1990s")
})

test_that("parse_speech_filename handles organizations", {
  result <- parse_speech_filename("IPCC-and-Gore_2007.txt")
  expect_equal(result$author, "IPCC and Gore")
  expect_equal(result$year, 2007)
  expect_equal(result$decade, "2000s")
})

test_that("parse_speech_filename handles complex names", {
  result <- parse_speech_filename("Ressa-and-Muratov_2021.txt")
  expect_equal(result$author, "Ressa and Muratov")
  expect_equal(result$year, 2021)
  expect_equal(result$decade, "2020s")
})

test_that("parse_speech_filename handles full path", {
  result <- parse_speech_filename("some/path/to/Churchill_1953.txt")
  expect_equal(result$author, "Churchill")
  expect_equal(result$year, 1953)
  expect_equal(result$filename, "Churchill_1953.txt")
})

test_that("parse_speech_filename handles EU abbreviation", {
  result <- parse_speech_filename("EU_2012.txt")
  expect_equal(result$author, "EU")
  expect_equal(result$year, 2012)
  expect_equal(result$decade, "2010s")
})

test_that("parse_speech_filename fails on bad filenames", {
  expect_error(parse_speech_filename("nounderscorefile.txt"))
})

cat("All filename parsing tests passed!\n")
