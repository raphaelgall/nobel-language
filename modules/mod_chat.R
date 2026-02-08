# Module: Ask Claude chat tab

chat_ui <- function(id) {
  ns <- NS(id)

  layout_sidebar(
    sidebar = sidebar(
      title = "Chat",
      width = 300,
      p("Ask questions about Nobel Prize speeches. Claude will use the speech corpus for context."),
      hr(),
      p(class = "text-muted small",
        "Try questions like:",
        tags$ul(
          tags$li("What themes does Faulkner explore?"),
          tags$li("Compare peace speeches from the 1990s"),
          tags$li("Which authors discuss war and reconciliation?")
        )
      ),
      hr(),
      actionButton(ns("clear_btn"), "Clear History", class = "btn-outline-secondary w-100")
    ),
    card(
      card_header("Conversation"),
      card_body(
        style = "height: 500px; overflow-y: auto;",
        uiOutput(ns("chat_history_ui"))
      ),
      card_footer(
        div(
          class = "d-flex gap-2",
          textInput(ns("user_input"), NULL,
            placeholder = "Ask about Nobel speeches...",
            width = "100%"
          ),
          actionButton(ns("send_btn"), "Send", class = "btn-primary")
        )
      )
    )
  )
}

chat_server <- function(id, con) {
  moduleServer(id, function(input, output, session) {

    chat_history <- reactiveVal(list())

    # Check if API key is available
    has_api_key <- reactive({
      Sys.getenv("ANTHROPIC_API_KEY") != ""
    })

    # Send message
    observeEvent(input$send_btn, {
      msg <- trimws(input$user_input)
      if (nchar(msg) == 0) return()

      if (!has_api_key()) {
        history <- chat_history()
        history <- c(history, list(
          list(role = "user", content = msg),
          list(role = "assistant", content = "**API key not configured.** Set ANTHROPIC_API_KEY in your .Renviron file and restart the app to enable chat.")
        ))
        chat_history(history)
        updateTextInput(session, "user_input", value = "")
        return()
      }

      # Add user message to history
      history <- chat_history()
      history <- c(history, list(list(role = "user", content = msg)))
      chat_history(history)
      updateTextInput(session, "user_input", value = "")

      # Get Claude's response
      tryCatch({
        # Build message list for API (only role + content)
        api_messages <- lapply(history, function(m) {
          list(role = m$role, content = m$content)
        })

        response <- chat_about_speeches(con, msg,
          chat_history = head(api_messages, -1)  # Exclude last user msg (added by function)
        )

        history <- c(history, list(list(role = "assistant", content = response)))
        chat_history(history)
      }, error = function(e) {
        history <- c(history, list(
          list(role = "assistant", content = paste("**Error:**", e$message))
        ))
        chat_history(history)
      })
    })

    # Clear history
    observeEvent(input$clear_btn, {
      chat_history(list())
    })

    # Render chat history
    output$chat_history_ui <- renderUI({
      history <- chat_history()

      if (length(history) == 0) {
        return(p(class = "text-muted text-center mt-4",
          "Start a conversation about Nobel Prize speeches."))
      }

      msgs <- lapply(history, function(m) {
        if (m$role == "user") {
          div(class = "d-flex justify-content-end mb-3",
            div(
              class = "bg-primary text-white rounded p-3",
              style = "max-width: 80%;",
              m$content
            )
          )
        } else {
          html_content <- tryCatch(
            commonmark::markdown_html(m$content),
            error = function(e) paste("<p>", htmltools::htmlEscape(m$content), "</p>")
          )
          div(class = "d-flex justify-content-start mb-3",
            div(
              class = "bg-light rounded p-3",
              style = "max-width: 80%;",
              HTML(html_content)
            )
          )
        }
      })

      tagList(msgs)
    })
  })
}
