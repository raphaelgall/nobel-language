# Module: Word Frequency Charts tab

word_frequency_ui <- function(id) {
  ns <- NS(id)

  layout_sidebar(
    sidebar = sidebar(
      title = "Options",
      width = 300,
      radioButtons(ns("category"), "Category",
        choices = c("All" = "all", "Literature" = "literature", "Peace" = "peace"),
        selected = "all"
      ),
      numericInput(ns("top_n"), "Top N Words", value = 10, min = 5, max = 50, step = 5),
      textInput(ns("custom_words"), "Custom Words",
        placeholder = "e.g. peace, war, freedom"
      ),
      helpText("Enter comma-separated words to track alongside top words"),
      actionButton(ns("update_btn"), "Update Chart", class = "btn-primary w-100")
    ),
    card(
      card_header("Word Frequency by Decade"),
      plotly::plotlyOutput(ns("freq_chart"), height = "500px")
    ),
    card(
      card_header("Raw Data"),
      DT::DTOutput(ns("freq_table"))
    )
  )
}

word_frequency_server <- function(id, con) {
  moduleServer(id, function(input, output, session) {

    freq_data <- reactiveVal(data.frame())

    # Load data on button click
    observeEvent(input$update_btn, {
      custom <- NULL
      if (nchar(trimws(input$custom_words)) > 0) {
        custom <- trimws(strsplit(input$custom_words, ",")[[1]])
        custom <- tolower(custom[nchar(custom) > 0])
      }

      data <- get_word_frequencies(con,
        category = input$category,
        top_n = input$top_n,
        custom_words = custom
      )
      freq_data(data)
    }, ignoreNULL = FALSE)

    # Also trigger on initial load
    observe({
      if (nrow(freq_data()) == 0) {
        data <- get_word_frequencies(con, category = "all", top_n = 10)
        freq_data(data)
      }
    })

    output$freq_chart <- plotly::renderPlotly({
      data <- freq_data()
      if (nrow(data) == 0) {
        return(plotly::plot_ly() %>%
          plotly::layout(title = "No data. Click 'Update Chart' to load."))
      }

      # Create line chart
      p <- ggplot2::ggplot(data,
        ggplot2::aes(x = decade, y = frequency, color = word, group = word)) +
        ggplot2::geom_line(linewidth = 0.8) +
        ggplot2::geom_point(size = 2) +
        ggplot2::labs(
          x = "Decade",
          y = "Frequency",
          color = "Word"
        ) +
        ggplot2::theme_minimal() +
        ggplot2::theme(
          axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
          legend.position = "right"
        )

      plotly::ggplotly(p, tooltip = c("word", "decade", "frequency")) %>%
        plotly::layout(legend = list(orientation = "v"))
    })

    output$freq_table <- DT::renderDT({
      data <- freq_data()
      if (nrow(data) == 0) return(DT::datatable(data.frame()))

      # Pivot wider for readability
      wide <- data %>%
        dplyr::select(word, decade, frequency) %>%
        tidyr::pivot_wider(names_from = decade, values_from = frequency, values_fill = 0)

      DT::datatable(wide,
        options = list(pageLength = 20, scrollX = TRUE),
        rownames = FALSE
      )
    })
  })
}
