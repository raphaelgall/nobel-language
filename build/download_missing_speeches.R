# Download missing Nobel Prize speeches from nobelprize.org
# Run this script once to complete the corpus

library(rvest)
library(httr)

# Helper: extract lecture text from a Nobel Prize lecture page
extract_lecture_text <- function(url) {
  resp <- GET(url, user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64)"))
  if (status_code(resp) != 200) {
    stop(sprintf("HTTP %d for %s", status_code(resp), url))
  }

  page <- read_html(content(resp, as = "text", encoding = "UTF-8"))

  # Find the entry-content article
  article <- html_element(page, "article.entry-content")
  if (is.na(article)) {
    stop("Could not find entry-content article in ", url)
  }

  # Check for "did not deliver" message
  article_text <- html_text(article)
  if (grepl("did not deliver", article_text, ignore.case = TRUE)) {
    return(NULL)
  }

  # Extract paragraphs from the article (skip header, nav, footer)
  paragraphs <- html_elements(article, "p")
  texts <- html_text2(paragraphs)

  # Filter out citation, copyright, and navigation text
  texts <- texts[nchar(texts) > 0]
  texts <- texts[!grepl("^To cite this section", texts)]
  texts <- texts[!grepl("^Copyright", texts)]
  texts <- texts[!grepl("^MLA style:", texts)]
  # Remove very short lines that are just navigation
  # But keep short paragraphs that are actual content

  paste(texts, collapse = "\n\n")
}

# Define missing speeches
missing_literature <- list(
  list(url = "https://www.nobelprize.org/prizes/literature/2020/gluck/lecture/",
       filename = "Gluck_2020.txt"),
  list(url = "https://www.nobelprize.org/prizes/literature/2021/gurnah/lecture/",
       filename = "Gurnah_2021.txt"),
  list(url = "https://www.nobelprize.org/prizes/literature/2022/ernaux/lecture/",
       filename = "Ernaux_2022.txt"),
  list(url = "https://www.nobelprize.org/prizes/literature/2023/fosse/lecture/",
       filename = "Fosse_2023.txt"),
  # Han Kang 2024: lecture not yet available (404)
  list(url = "https://www.nobelprize.org/prizes/literature/2025/krasznahorkai/lecture/",
       filename = "Krasznahorkai_2025.txt")
)

missing_peace <- list(
  list(url = "https://www.nobelprize.org/prizes/peace/1971/brandt/lecture/",
       filename = "Brandt_1971.txt"),
  list(url = "https://www.nobelprize.org/prizes/peace/2020/wfp/lecture/",
       filename = "WFP_2020.txt"),
  list(url = "https://www.nobelprize.org/prizes/peace/2021/ressa/lecture/",
       filename = "Ressa-and-Muratov_2021.txt"),
  list(url = "https://www.nobelprize.org/prizes/peace/2022/bialiatski/lecture/",
       filename = "Bialiatski-Memorial-and-CCL_2022.txt"),
  list(url = "https://www.nobelprize.org/prizes/peace/2023/mohammadi/lecture/",
       filename = "Mohammadi_2023.txt"),
  list(url = "https://www.nobelprize.org/prizes/peace/2024/nihon-hidankyo/lecture/",
       filename = "Nihon-Hidankyo_2024.txt"),
  list(url = "https://www.nobelprize.org/prizes/peace/2025/machado/lecture/",
       filename = "Machado_2025.txt")
)

# Additional URLs for shared prizes
peace_2021_muratov <- "https://www.nobelprize.org/prizes/peace/2021/muratov/lecture/"
peace_2022_ccl <- "https://www.nobelprize.org/prizes/peace/2022/center-for-civil-liberties/lecture/"
peace_2022_memorial <- "https://www.nobelprize.org/prizes/peace/2022/memorial/lecture/"

base_lit <- "G:/My Drive/playing/Nobel language/nobelprizestats/nobelprize_lit/all"
base_pea <- "G:/My Drive/playing/Nobel language/nobelprizestats/nobelprize_pea/all"

# Download literature speeches
cat("=== Downloading Literature Speeches ===\n")
for (speech in missing_literature) {
  cat(sprintf("  %s ... ", speech$filename))
  tryCatch({
    text <- extract_lecture_text(speech$url)
    if (is.null(text)) {
      cat("SKIPPED (no lecture)\n")
      next
    }
    filepath <- file.path(base_lit, speech$filename)
    writeLines(text, filepath, useBytes = FALSE)
    cat(sprintf("OK (%d chars)\n", nchar(text)))
  }, error = function(e) {
    cat(sprintf("ERROR: %s\n", e$message))
  })
  Sys.sleep(2)
}

# Download peace speeches
cat("\n=== Downloading Peace Speeches ===\n")
for (speech in missing_peace) {
  cat(sprintf("  %s ... ", speech$filename))
  tryCatch({
    text <- extract_lecture_text(speech$url)
    if (is.null(text)) {
      cat("SKIPPED (no lecture)\n")
      next
    }

    # Handle shared prize: 2021 Ressa + Muratov
    if (speech$filename == "Ressa-and-Muratov_2021.txt") {
      cat("OK\n    + Muratov ... ")
      muratov_text <- extract_lecture_text(peace_2021_muratov)
      if (!is.null(muratov_text)) {
        text <- paste0(
          "=== Maria Ressa ===\n\n", text,
          "\n\n\n=== Dmitry Muratov ===\n\n", muratov_text
        )
        cat("OK")
      }
      Sys.sleep(2)
    }

    # Handle shared prize: 2022 Bialiatski + Memorial + CCL
    if (speech$filename == "Bialiatski-Memorial-and-CCL_2022.txt") {
      combined <- paste0("=== Ales Bialiatski ===\n\n", text)
      cat("OK\n    + Memorial ... ")
      mem_text <- extract_lecture_text(peace_2022_memorial)
      if (!is.null(mem_text)) {
        combined <- paste0(combined, "\n\n\n=== Memorial ===\n\n", mem_text)
        cat("OK")
      }
      Sys.sleep(2)
      cat("\n    + CCL ... ")
      ccl_text <- extract_lecture_text(peace_2022_ccl)
      if (!is.null(ccl_text)) {
        combined <- paste0(combined, "\n\n\n=== Center for Civil Liberties ===\n\n", ccl_text)
        cat("OK")
      }
      text <- combined
      Sys.sleep(2)
    }

    filepath <- file.path(base_pea, speech$filename)
    writeLines(text, filepath, useBytes = FALSE)
    cat(sprintf("\n    Saved (%d chars)\n", nchar(text)))
  }, error = function(e) {
    cat(sprintf("ERROR: %s\n", e$message))
  })
  Sys.sleep(2)
}

cat("\n=== Summary ===\n")
cat(sprintf("Literature files: %d\n", length(list.files(base_lit, pattern = "\\.txt$"))))
cat(sprintf("Peace files: %d\n", length(list.files(base_pea, pattern = "\\.txt$"))))
