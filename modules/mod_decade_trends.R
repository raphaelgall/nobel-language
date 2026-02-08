# Module: Decade Trends tab (pre-computed Claude summaries)

decade_trends_ui <- function(id) {
  ns <- NS(id)

  layout_sidebar(
    sidebar = sidebar(
      title = "Options",
      width = 250,
      radioButtons(ns("category"), "Category",
        choices = c("Literature" = "literature", "Peace" = "peace"),
        selected = "literature"
      )
    ),
    uiOutput(ns("decade_cards"))
  )
}

decade_trends_server <- function(id, con) {
  moduleServer(id, function(input, output, session) {

    output$decade_cards <- renderUI({
      ns <- session$ns

      summaries <- get_decade_summaries(con, category = input$category)
      decades <- get_decades(con)

      if (nrow(summaries) == 0) {
        return(card(
          card_header("No Summaries Available"),
          card_body(
            p("Decade summaries have not been generated yet."),
            p("Run ", code("Rscript build/build_decade_summaries.R"),
              " with your ANTHROPIC_API_KEY set to generate them.")
          )
        ))
      }

      # Create a card for each decade
      cards <- lapply(decades, function(d) {
        summary_row <- summaries[summaries$decade == d, ]
        if (nrow(summary_row) == 0) {
          card(
            card_header(d),
            card_body(
              p(class = "text-muted", "No summary available for this decade.")
            )
          )
        } else {
          # Render markdown
          html_content <- commonmark::markdown_html(summary_row$summary_text[1])
          card(
            card_header(
              span(d),
              span(class = "text-muted small ms-2",
                sprintf("Generated: %s", summary_row$generated_at[1]))
            ),
            card_body(HTML(html_content))
          )
        }
      })

      tagList(cards)
    })
  })
}
