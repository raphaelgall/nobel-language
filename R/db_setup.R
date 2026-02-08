# SQLite database schema and ingestion functions

library(DBI)
library(RSQLite)

#' Create the SQLite database schema
#' @param db_path Path to the SQLite database file
#' @return A DBI connection object
create_database <- function(db_path) {
  if (file.exists(db_path)) {
    file.remove(db_path)
  }
  dir.create(dirname(db_path), showWarnings = FALSE, recursive = TRUE)

  con <- dbConnect(SQLite(), db_path)

  # Main speeches table
dbExecute(con, "
    CREATE TABLE speeches (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      year INTEGER NOT NULL,
      author TEXT NOT NULL,
      category TEXT NOT NULL CHECK(category IN ('literature', 'peace')),
      text TEXT NOT NULL,
      decade TEXT NOT NULL,
      filename TEXT NOT NULL UNIQUE
    )
  ")

  # Indexes
  dbExecute(con, "CREATE INDEX idx_speeches_year ON speeches(year)")
  dbExecute(con, "CREATE INDEX idx_speeches_category ON speeches(category)")
  dbExecute(con, "CREATE INDEX idx_speeches_decade ON speeches(decade)")
  dbExecute(con, "CREATE INDEX idx_speeches_author ON speeches(author)")

  # FTS5 virtual table for full-text search
  dbExecute(con, "
    CREATE VIRTUAL TABLE speeches_fts USING fts5(
      author, text, category,
      content='speeches',
      content_rowid='id'
    )
  ")

  # Triggers to keep FTS in sync
  dbExecute(con, "
    CREATE TRIGGER speeches_ai AFTER INSERT ON speeches BEGIN
      INSERT INTO speeches_fts(rowid, author, text, category)
      VALUES (new.id, new.author, new.text, new.category);
    END
  ")

  dbExecute(con, "
    CREATE TRIGGER speeches_ad AFTER DELETE ON speeches BEGIN
      INSERT INTO speeches_fts(speeches_fts, rowid, author, text, category)
      VALUES ('delete', old.id, old.author, old.text, old.category);
    END
  ")

  dbExecute(con, "
    CREATE TRIGGER speeches_au AFTER UPDATE ON speeches BEGIN
      INSERT INTO speeches_fts(speeches_fts, rowid, author, text, category)
      VALUES ('delete', old.id, old.author, old.text, old.category);
      INSERT INTO speeches_fts(rowid, author, text, category)
      VALUES (new.id, new.author, new.text, new.category);
    END
  ")

  # Word frequencies table
  dbExecute(con, "
    CREATE TABLE word_frequencies (
      word TEXT NOT NULL,
      decade TEXT NOT NULL,
      category TEXT NOT NULL,
      frequency INTEGER NOT NULL,
      tf_idf REAL,
      PRIMARY KEY (word, decade, category)
    )
  ")

  dbExecute(con, "CREATE INDEX idx_wf_decade_category ON word_frequencies(decade, category)")
  dbExecute(con, "CREATE INDEX idx_wf_word ON word_frequencies(word)")

  # Decade summaries table
  dbExecute(con, "
    CREATE TABLE decade_summaries (
      decade TEXT NOT NULL,
      category TEXT NOT NULL,
      summary_text TEXT NOT NULL,
      generated_at TEXT NOT NULL,
      PRIMARY KEY (decade, category)
    )
  ")

  con
}

#' Ingest speech files into the database
#' @param con DBI connection
#' @param directory Path to directory of .txt files
#' @param category "literature" or "peace"
#' @return Number of speeches ingested
ingest_speeches <- function(con, directory, category) {
  files <- list.files(directory, pattern = "\\.txt$", full.names = TRUE)

  if (length(files) == 0) {
    warning("No .txt files found in ", directory)
    return(0)
  }

  count <- 0
  for (filepath in files) {
    tryCatch({
      parsed <- parse_speech_filename(filepath)
      text <- read_speech_file(filepath)

      if (nchar(trimws(text)) == 0) {
        message("  Skipping empty file: ", basename(filepath))
        next
      }

      dbExecute(con, "
        INSERT INTO speeches (year, author, category, text, decade, filename)
        VALUES (?, ?, ?, ?, ?, ?)
      ", params = list(
        parsed$year, parsed$author, category, text, parsed$decade, parsed$filename
      ))

      count <- count + 1
    }, error = function(e) {
      message("  Error ingesting ", basename(filepath), ": ", e$message)
    })
  }

  count
}
