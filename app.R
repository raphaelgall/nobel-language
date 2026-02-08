# Nobel Prize Speech Explorer — Shiny App

library(shiny)
library(bslib)
library(DBI)
library(RSQLite)
library(DT)
library(plotly)
library(dplyr)
library(tidyr)
library(ggplot2)
library(commonmark)

# Source R modules and utilities
source("R/utils.R")
source("R/db_setup.R")
source("R/db_queries.R")
source("R/claude_api.R")
source("modules/mod_speech_browser.R")
source("modules/mod_search.R")
source("modules/mod_word_frequency.R")
source("modules/mod_decade_trends.R")
source("modules/mod_chat.R")

# Database path
db_path <- "data/nobel_speeches.db"

# UI
ui <- page_navbar(
  title = "Nobel Prize Speech Explorer",
  theme = bs_theme(bootswatch = "flatly"),
  header = tags$head(
    tags$link(rel = "stylesheet", href = "custom.css")
  ),

  nav_panel("Browse Speeches",
    icon = icon("book-open"),
    speech_browser_ui("browser")
  ),

  nav_panel("Search",
    icon = icon("search"),
    search_ui("search")
  ),

  nav_panel("Word Frequencies",
    icon = icon("chart-line"),
    word_frequency_ui("wordfreq")
  ),

  nav_panel("Decade Trends",
    icon = icon("clock-rotate-left"),
    decade_trends_ui("trends")
  ),

  nav_panel("Ask Claude",
    icon = icon("comments"),
    chat_ui("chat")
  ),

  nav_spacer(),
  nav_item(
    tags$a(
      href = "https://github.com/raphaelgall/nobel-language",
      target = "_blank",
      icon("github"), "Source"
    )
  )
)

# Server
server <- function(input, output, session) {
  # Open database connection (shared across all modules)
  if (!file.exists(db_path)) {
    showModal(modalDialog(
      title = "Database Not Found",
      p("The database has not been built yet."),
      p("Run ", code("Rscript build/build_all.R"), " from the project root to build it."),
      easyClose = TRUE,
      footer = modalButton("OK")
    ))
    return()
  }

  con <- dbConnect(SQLite(), db_path)

  # Close connection when app stops
  onStop(function() {
    dbDisconnect(con)
  })

  # Initialize modules
  speech_browser_server("browser", con)
  search_server("search", con)
  word_frequency_server("wordfreq", con)
  decade_trends_server("trends", con)
  chat_server("chat", con)
}

shinyApp(ui, server)
