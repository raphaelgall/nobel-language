# Text processing pipeline using tidytext

library(tidytext)
library(dplyr)
library(tidyr)
library(stringr)
library(SnowballC)

#' Compute word frequencies from the speeches table
#' @param con DBI connection to the SQLite database
#' @param use_stemming Whether to apply Porter stemming
#' @return Data frame with word, decade, category, frequency, tf_idf
compute_word_frequencies <- function(con, use_stemming = FALSE) {
  # Load all speeches
  speeches <- dbGetQuery(con, "SELECT id, decade, category, text FROM speeches")

  # Tokenize
  tokens <- speeches %>%
    unnest_tokens(word, text) %>%
    # Remove numbers-only tokens
    filter(!str_detect(word, "^\\d+$")) %>%
    # Remove very short words
    filter(nchar(word) >= 3) %>%
    # Remove stop words
    anti_join(stop_words, by = "word")

  # Optional stemming
  if (use_stemming) {
    tokens <- tokens %>%
      mutate(word = wordStem(word, language = "en"))
  }

  # Count by word, decade, category
  word_counts <- tokens %>%
    count(word, decade, category, name = "frequency") %>%
    mutate(document = paste(decade, category, sep = "."))

  # Compute TF-IDF: treat each decade x category as a "document"
  word_tfidf <- word_counts %>%
    bind_tf_idf(word, document, frequency)

  # Return combined result
  word_tfidf %>%
    select(word, decade, category, frequency, tf_idf) %>%
    arrange(decade, category, desc(frequency))
}

#' Store word frequencies in the database
#' @param con DBI connection
#' @param freq_df Data frame from compute_word_frequencies()
store_word_frequencies <- function(con, freq_df) {
  # Clear existing data
  dbExecute(con, "DELETE FROM word_frequencies")

  # Batch insert
  dbWriteTable(con, "word_frequencies", freq_df, append = TRUE, row.names = FALSE)
}
