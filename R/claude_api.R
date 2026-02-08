# Claude API wrapper for summaries and chat

library(httr2)
library(jsonlite)

#' Call Claude API
#' @param messages List of message objects (role + content)
#' @param system_prompt System prompt string
#' @param max_tokens Maximum tokens in response
#' @return Character string with Claude's response
call_claude <- function(messages, system_prompt = NULL, max_tokens = 1024) {
  api_key <- Sys.getenv("ANTHROPIC_API_KEY")
  if (api_key == "") {
    stop("ANTHROPIC_API_KEY not set. Add it to .Renviron or set it in your environment.")
  }

  body <- list(
    model = "claude-sonnet-4-5-20250929",
    max_tokens = max_tokens,
    messages = messages
  )
  if (!is.null(system_prompt)) {
    body$system <- system_prompt
  }

  resp <- request("https://api.anthropic.com/v1/messages") |>
    req_headers(
      `x-api-key` = api_key,
      `anthropic-version` = "2023-06-01",
      `content-type` = "application/json"
    ) |>
    req_body_json(body) |>
    req_timeout(120) |>
    req_perform()

  result <- resp_body_json(resp)

  # Extract text from response
  if (!is.null(result$content) && length(result$content) > 0) {
    paste(sapply(result$content, function(block) block$text), collapse = "\n")
  } else {
    stop("Unexpected API response format")
  }
}

#' Generate a decade summary for a given category
#' @param con DBI connection
#' @param decade e.g. "1950s"
#' @param category "literature" or "peace"
#' @return Character string with the summary
generate_decade_summary <- function(con, decade, category) {
  speeches <- get_speeches_for_decade(con, decade, category)

  if (nrow(speeches) == 0) {
    return(paste("No", category, "speeches available for the", decade))
  }

  # Get top words for context
  top_words <- dbGetQuery(con, "
    SELECT word, frequency FROM word_frequencies
    WHERE decade = ? AND category = ?
    ORDER BY frequency DESC
    LIMIT 20
  ", params = list(decade, category))

  # Build excerpts (first 500 chars of each speech)
  excerpts <- sapply(seq_len(nrow(speeches)), function(i) {
    sprintf("**%s (%d)**: %s...",
            speeches$author[i], speeches$year[i],
            substr(speeches$text[i], 1, 500))
  })

  system_prompt <- paste(
    "You are a literary and political analyst summarizing Nobel Prize speeches.",
    "Write a concise, insightful summary (2-3 paragraphs) of the themes and",
    "rhetoric in these speeches. Note common threads and distinctive voices.",
    "Use markdown formatting."
  )

  user_message <- sprintf(
    "Summarize the %s Nobel Prize %s speeches from the %s.\n\n## Top Words\n%s\n\n## Speech Excerpts\n%s",
    category,
    if (category == "literature") "lectures" else "lectures",
    decade,
    paste(sprintf("- %s (%d)", top_words$word, top_words$frequency), collapse = "\n"),
    paste(excerpts, collapse = "\n\n")
  )

  messages <- list(
    list(role = "user", content = user_message)
  )

  call_claude(messages, system_prompt, max_tokens = 1500)
}

#' Chat about Nobel speeches with context injection
#' @param con DBI connection
#' @param user_message User's question
#' @param chat_history List of previous messages
#' @return Character string with Claude's response
chat_about_speeches <- function(con, user_message, chat_history = list()) {
  # Try to find relevant speeches mentioned in the user's message
  context <- ""

  # Search for author names or years in the message
  search_results <- tryCatch({
    fts_search(con, user_message, search_type = "both")
  }, error = function(e) data.frame())

  if (nrow(search_results) > 0) {
    # Get full text of top 3 matches
    top_ids <- head(search_results$id, 3)
    for (id in top_ids) {
      speech <- get_speech_by_id(con, id)
      # Include first 2000 chars for context
      excerpt <- substr(speech$text, 1, 2000)
      context <- paste0(context, sprintf(
        "\n\n---\n**%s (%d, %s)**:\n%s",
        speech$author, speech$year, speech$category, excerpt
      ))
    }
  }

  system_prompt <- paste(
    "You are a knowledgeable assistant helping users explore Nobel Prize speeches",
    "(both Literature and Peace). You have access to the full corpus of speeches.",
    "Answer questions insightfully, citing specific speeches and authors when relevant.",
    "Use markdown formatting for readability."
  )

  if (nchar(context) > 0) {
    system_prompt <- paste0(system_prompt,
      "\n\nHere are relevant speech excerpts from the corpus:\n", context)
  }

  messages <- c(chat_history, list(
    list(role = "user", content = user_message)
  ))

  call_claude(messages, system_prompt, max_tokens = 2000)
}
