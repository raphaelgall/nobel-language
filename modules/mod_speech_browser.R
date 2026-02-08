# Module: Browse Speeches tab

speech_browser_ui <- function(id) {
  ns <- NS(id)

  layout_sidebar(
    sidebar = sidebar(
      title = "Filters",
      width = 300,
      radioButtons(ns("category"), "Category",
        choices = c("All" = "all", "Literature" = "literature", "Peace" = "peace"),
        selected = "all"
      ),
      sliderInput(ns("year_range"), "Year Range",
        min = 1940, max = 2025, value = c(1940, 2025),
        step = 1, sep = ""
      ),
      selectizeInput(ns("author"), "Author",
        choices = NULL,
        options = list(placeholder = "Type to search...")
      )
    ),
    card(
      card_header("Speeches"),
      DT::DTOutput(ns("speech_table"))
    ),
    card(
      card_header(textOutput(ns("speech_title"))),
      div(
        style = "max-height: 500px; overflow-y: auto; white-space: pre-wrap; font-family: Georgia, serif; line-height: 1.6;",
        textOutput(ns("speech_text"))
      )
    )
  )
}

speech_browser_server <- function(id, con) {
  moduleServer(id, function(input, output, session) {

    # Populate author dropdown
    observe({
      authors <- get_authors(con)
      updateSelectizeInput(session, "author",
        choices = c("" = "", authors),
        server = TRUE
      )
    })

    # Update year range from data
    observe({
      yr <- get_year_range(con)
      updateSliderInput(session, "year_range",
        min = yr$min_year, max = yr$max_year,
        value = c(yr$min_year, yr$max_year)
      )
    })

    # Filtered data
    filtered_data <- reactive({
      get_speeches_filtered(con,
        category = input$category,
        year_min = input$year_range[1],
        year_max = input$year_range[2],
        author = if (is.null(input$author) || input$author == "") NULL else input$author
      )
    })

    # Render table
    output$speech_table <- DT::renderDT({
      df <- filtered_data()
      df_display <- df[, c("year", "author", "category", "decade")]
      DT::datatable(df_display,
        selection = "single",
        options = list(
          pageLength = 15,
          order = list(list(0, "asc"))
        ),
        rownames = FALSE,
        colnames = c("Year", "Author", "Category", "Decade")
      )
    })

    # Selected speech
    selected_speech <- reactive({
      row <- input$speech_table_rows_selected
      if (is.null(row) || length(row) == 0) return(NULL)
      df <- filtered_data()
      if (row > nrow(df)) return(NULL)
      get_speech_by_id(con, df$id[row])
    })

    output$speech_title <- renderText({
      speech <- selected_speech()
      if (is.null(speech)) {
        "Select a speech from the table above"
      } else {
        sprintf("%s (%d) - %s", speech$author, speech$year,
                tools::toTitleCase(speech$category))
      }
    })

    output$speech_text <- renderText({
      speech <- selected_speech()
      if (is.null(speech)) {
        "Click on a row in the table to view the full speech text."
      } else {
        speech$text
      }
    })
  })
}
