# Module: Full-text Search tab

search_ui <- function(id) {
  ns <- NS(id)

  layout_sidebar(
    sidebar = sidebar(
      title = "Search",
      width = 300,
      textInput(ns("query"), "Search Query", placeholder = "Enter search terms..."),
      radioButtons(ns("search_type"), "Search In",
        choices = c("Author & Text" = "both", "Author Only" = "author", "Full Text" = "fulltext"),
        selected = "both"
      ),
      radioButtons(ns("category"), "Category",
        choices = c("All" = "all", "Literature" = "literature", "Peace" = "peace"),
        selected = "all"
      ),
      actionButton(ns("search_btn"), "Search", class = "btn-primary w-100")
    ),
    card(
      card_header(textOutput(ns("result_count"))),
      DT::DTOutput(ns("results_table"))
    ),
    card(
      card_header(textOutput(ns("detail_title"))),
      div(
        style = "max-height: 500px; overflow-y: auto; white-space: pre-wrap; font-family: Georgia, serif; line-height: 1.6;",
        uiOutput(ns("detail_text"))
      )
    )
  )
}

search_server <- function(id, con) {
  moduleServer(id, function(input, output, session) {

    search_results <- reactiveVal(data.frame())

    # Perform search on button click or Enter
    observeEvent(input$search_btn, {
      query <- trimws(input$query)
      if (nchar(query) == 0) {
        search_results(data.frame())
        return()
      }

      tryCatch({
        results <- fts_search(con, query,
          category = input$category,
          search_type = input$search_type
        )
        search_results(results)
      }, error = function(e) {
        search_results(data.frame())
        showNotification(paste("Search error:", e$message), type = "error")
      })
    })

    output$result_count <- renderText({
      results <- search_results()
      if (nrow(results) == 0 && nchar(trimws(input$query)) > 0) {
        "No results found"
      } else if (nrow(results) == 0) {
        "Enter a search query"
      } else {
        sprintf("%d results found", nrow(results))
      }
    })

    output$results_table <- DT::renderDT({
      results <- search_results()
      if (nrow(results) == 0) return(DT::datatable(data.frame()))

      df <- data.frame(
        Year = results$year,
        Author = results$author,
        Category = results$category,
        Snippet = results$snippet,
        stringsAsFactors = FALSE
      )

      DT::datatable(df,
        selection = "single",
        escape = FALSE,  # Allow HTML in snippet column
        options = list(
          pageLength = 10,
          order = list(list(0, "asc"))
        ),
        rownames = FALSE
      )
    })

    output$detail_title <- renderText({
      row <- input$results_table_rows_selected
      if (is.null(row) || length(row) == 0) {
        return("Select a result to view full text")
      }
      results <- search_results()
      if (row > nrow(results)) return("")
      sprintf("%s (%d) - %s", results$author[row], results$year[row],
              tools::toTitleCase(results$category[row]))
    })

    output$detail_text <- renderUI({
      row <- input$results_table_rows_selected
      if (is.null(row) || length(row) == 0) {
        return(tags$p("Click a row to see the full speech."))
      }
      results <- search_results()
      if (row > nrow(results)) return(NULL)

      speech <- get_speech_by_id(con, results$id[row])
      if (is.null(speech) || nrow(speech) == 0) return(NULL)

      # Highlight search terms in the text
      text <- speech$text
      query <- trimws(input$query)
      if (nchar(query) > 0) {
        # Simple case-insensitive highlight
        text <- gsub(
          paste0("(", gsub("([.\\^$|*+?{}\\[\\]()])", "\\\\\\1", query), ")"),
          "<mark>\\1</mark>",
          text, ignore.case = TRUE
        )
      }

      HTML(paste0("<div style='white-space: pre-wrap;'>", text, "</div>"))
    })
  })
}
