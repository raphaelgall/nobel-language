# Database query functions used by Shiny modules

library(DBI)

#' Get all speech metadata (no full text)
get_speech_metadata <- function(con) {
  dbGetQuery(con, "
    SELECT id, year, author, category, decade, filename,
           length(text) as text_length
    FROM speeches
    ORDER BY year, author
  ")
}

#' Get a single speech by ID
get_speech_by_id <- function(con, speech_id) {
  dbGetQuery(con, "
    SELECT * FROM speeches WHERE id = ?
  ", params = list(speech_id))
}

#' Get speeches filtered by category, year range, and/or author
get_speeches_filtered <- function(con, category = NULL, year_min = NULL,
                                  year_max = NULL, author = NULL) {
  where <- character()
  params <- list()

  if (!is.null(category) && category != "all") {
    where <- c(where, "category = ?")
    params <- c(params, list(category))
  }
  if (!is.null(year_min)) {
    where <- c(where, "year >= ?")
    params <- c(params, list(year_min))
  }
  if (!is.null(year_max)) {
    where <- c(where, "year <= ?")
    params <- c(params, list(year_max))
  }
  if (!is.null(author) && author != "") {
    where <- c(where, "author LIKE ?")
    params <- c(params, list(paste0("%", author, "%")))
  }

  sql <- "SELECT id, year, author, category, decade, filename,
                 length(text) as text_length FROM speeches"
  if (length(where) > 0) {
    sql <- paste(sql, "WHERE", paste(where, collapse = " AND "))
  }
  sql <- paste(sql, "ORDER BY year, author")

  dbGetQuery(con, sql, params = params)
}

#' Full-text search using FTS5
fts_search <- function(con, query, category = NULL, search_type = "both") {
  # Build the FTS query based on search type
  fts_query <- switch(search_type,
    "author" = paste0("author:", query),
    "fulltext" = paste0("text:", query),
    "both" = query
  )

  where_extra <- ""
  params <- list(fts_query, fts_query)

  if (!is.null(category) && category != "all") {
    where_extra <- "AND s.category = ?"
    params <- c(params, list(category))
  }

  sql <- sprintf("
    SELECT s.id, s.year, s.author, s.category, s.decade,
           snippet(speeches_fts, 1, '<mark>', '</mark>', '...', 40) as snippet,
           rank
    FROM speeches_fts
    JOIN speeches s ON s.id = speeches_fts.rowid
    WHERE speeches_fts MATCH ?
    %s
    ORDER BY rank
    LIMIT 100
  ", where_extra)

  dbGetQuery(con, sql, params = params)
}

#' Get word frequencies for charting
get_word_frequencies <- function(con, category = "all", top_n = 20,
                                 custom_words = NULL) {
  params <- list()
  where <- character()

  if (category != "all") {
    where <- c(where, "category = ?")
    params <- c(params, list(category))
  }

  # Get top N words by total frequency
  where_clause <- if (length(where) > 0) paste("WHERE", paste(where, collapse = " AND ")) else ""

  top_words_sql <- sprintf("
    SELECT word, SUM(frequency) as total_freq
    FROM word_frequencies
    %s
    GROUP BY word
    ORDER BY total_freq DESC
    LIMIT ?
  ", where_clause)

  top_words <- dbGetQuery(con, top_words_sql, params = c(params, list(top_n)))

  # Combine top words with any custom words
  all_words <- top_words$word
  if (!is.null(custom_words) && length(custom_words) > 0) {
    all_words <- unique(c(all_words, custom_words))
  }

  if (length(all_words) == 0) return(data.frame())

  # Get frequencies by decade for these words
  placeholders <- paste(rep("?", length(all_words)), collapse = ",")
  freq_params <- as.list(all_words)

  if (category != "all") {
    freq_sql <- sprintf("
      SELECT word, decade, frequency, tf_idf
      FROM word_frequencies
      WHERE word IN (%s) AND category = ?
      ORDER BY decade, word
    ", placeholders)
    freq_params <- c(freq_params, list(category))
  } else {
    freq_sql <- sprintf("
      SELECT word, decade, SUM(frequency) as frequency, AVG(tf_idf) as tf_idf
      FROM word_frequencies
      WHERE word IN (%s)
      GROUP BY word, decade
      ORDER BY decade, word
    ", placeholders)
  }

  dbGetQuery(con, freq_sql, params = freq_params)
}

#' Get decade summaries
get_decade_summaries <- function(con, category = NULL) {
  if (!is.null(category) && category != "all") {
    dbGetQuery(con, "
      SELECT * FROM decade_summaries
      WHERE category = ?
      ORDER BY decade
    ", params = list(category))
  } else {
    dbGetQuery(con, "SELECT * FROM decade_summaries ORDER BY decade, category")
  }
}

#' Get unique authors
get_authors <- function(con) {
  dbGetQuery(con, "SELECT DISTINCT author FROM speeches ORDER BY author")$author
}

#' Get year range
get_year_range <- function(con) {
  dbGetQuery(con, "SELECT MIN(year) as min_year, MAX(year) as max_year FROM speeches")
}

#' Get available decades
get_decades <- function(con) {
  dbGetQuery(con, "SELECT DISTINCT decade FROM speeches ORDER BY decade")$decade
}

#' Get speeches for a specific decade and category (for Claude API)
get_speeches_for_decade <- function(con, decade, category) {
  dbGetQuery(con, "
    SELECT author, year, text FROM speeches
    WHERE decade = ? AND category = ?
    ORDER BY year
  ", params = list(decade, category))
}
