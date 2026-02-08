# Filename parsing and encoding helpers

#' Parse a speech filename into author, year, and decade
#' @param filename Character string like "Faulkner_1949.txt" or "Mandela-and-deKlerk_1993.txt"
#' @return A named list with author, year, decade
parse_speech_filename <- function(filename) {
  # Remove .txt extension
  base <- sub("\\.txt$", "", basename(filename))

  # Split on the LAST underscore to separate author from year
  last_underscore <- regexpr("_[^_]*$", base)
  if (last_underscore == -1) {
    stop("Cannot parse filename: ", filename)
  }

  author_part <- substr(base, 1, last_underscore - 1)
  year_part <- substr(base, last_underscore + 1, nchar(base))

  year <- as.integer(year_part)
  if (is.na(year)) {
    stop("Cannot parse year from filename: ", filename)
  }

  # Convert hyphens to spaces for display, but keep "and" as connector
  author <- gsub("-", " ", author_part)

  # Compute decade

  decade <- paste0(floor(year / 10) * 10, "s")

  list(
    author = author,
    year = year,
    decade = decade,
    filename = basename(filename)
  )
}

#' Read a speech file with encoding handling
#' @param filepath Path to a .txt file
#' @return Character string with the speech text
read_speech_file <- function(filepath) {
  # Try UTF-8 first (handles BOM via encoding detection)
  text <- tryCatch(
    {
      raw <- readBin(filepath, "raw", file.info(filepath)$size)
      # Check for UTF-8 BOM (EF BB BF)
      if (length(raw) >= 3 && raw[1] == as.raw(0xEF) &&
        raw[2] == as.raw(0xBB) && raw[3] == as.raw(0xBF)) {
        raw <- raw[4:length(raw)]
      }
      txt <- rawToChar(raw)
      Encoding(txt) <- "UTF-8"
      # Validate UTF-8 by trying to use it
      nchar(txt)
      txt
    },
    error = function(e) NULL
  )

  if (is.null(text)) {
    # Fallback to latin1
    text <- readLines(filepath, encoding = "latin1", warn = FALSE)
    text <- paste(text, collapse = "\n")
    text <- iconv(text, from = "latin1", to = "UTF-8")
  }

  # Clean smart quotes and other problematic characters
  text <- gsub("\u2018|\u2019", "'", text)   # smart single quotes
  text <- gsub("\u201c|\u201d", '"', text)   # smart double quotes
  text <- gsub("\u2013", "-", text)          # en dash
  text <- gsub("\u2014", "--", text)         # em dash
  text <- gsub("\u2026", "...", text)        # ellipsis
  text <- gsub("\r\n", "\n", text)           # normalize line endings

  trimws(text)
}
