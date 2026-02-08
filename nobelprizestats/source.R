#nobelprize analysis with statistical techniques.
#explorative analysis, including machine learning, quantitative text analysis.
#source file

#libraries, installed only once.
#neededpackages   <- c("tm", "SnowballCC", "RColorBrewer", "ggplot2", "wordcloud", "biclust", "cluster", "igraph", "fpc", "psych", "ggvis")
#install.packages(neededpackages, dependencies=TRUE)

library('tm')
library('wordcloud')
library('SnowballC')
library('ggplot2')
library('cluster')
library('fpc')
library('psych')
library('ggvis')

#load texts for all years per prize
peacedata           <- file.path("nobelprize_pea/1940_2016")
literaturedata      <- file.path("nobelprize_lit/1949_2016")

nobel_peace         <- Corpus(DirSource(peacedata))
nobel_literature    <- Corpus(DirSource(literaturedata))

#load texts for each decade separatly per prize
peacedata_1940      <-   file.path("nobelprize_pea/1940")
peacedata_1950      <-   file.path("nobelprize_pea/1950")
peacedata_1960      <-   file.path("nobelprize_pea/1960")
peacedata_1970      <-   file.path("nobelprize_pea/1970")
peacedata_1980      <-   file.path("nobelprize_pea/1980")
peacedata_1990      <-   file.path("nobelprize_pea/1990")
peacedata_2000      <-   file.path("nobelprize_pea/2000")
peacedata_2010      <-   file.path("nobelprize_pea/2010")

nobel_peace_1940         <- Corpus(DirSource(peacedata_1940))
nobel_peace_1950         <- Corpus(DirSource(peacedata_1950))
nobel_peace_1960         <- Corpus(DirSource(peacedata_1960))
nobel_peace_1970         <- Corpus(DirSource(peacedata_1970))
nobel_peace_1980         <- Corpus(DirSource(peacedata_1980))
nobel_peace_1990         <- Corpus(DirSource(peacedata_1990))
nobel_peace_2000         <- Corpus(DirSource(peacedata_2000))
nobel_peace_2010         <- Corpus(DirSource(peacedata_2010))

literaturedata_1940      <-   file.path("nobelprize_lit/1940")
literaturedata_1950      <-   file.path("nobelprize_lit/1950")
literaturedata_1960      <-   file.path("nobelprize_lit/1960")
literaturedata_1970      <-   file.path("nobelprize_lit/1970")
literaturedata_1980      <-   file.path("nobelprize_lit/1980")
literaturedata_1990      <-   file.path("nobelprize_lit/1990")
literaturedata_2000      <-   file.path("nobelprize_lit/2000")
literaturedata_2010      <-   file.path("nobelprize_lit/2010")

nobel_literature_1940         <- Corpus(DirSource(literaturedata_1940))
nobel_literature_1950         <- Corpus(DirSource(literaturedata_1950))
nobel_literature_1960         <- Corpus(DirSource(literaturedata_1960))
nobel_literature_1970         <- Corpus(DirSource(literaturedata_1970))
nobel_literature_1980         <- Corpus(DirSource(literaturedata_1980))
nobel_literature_1990         <- Corpus(DirSource(literaturedata_1990))
nobel_literature_2000         <- Corpus(DirSource(literaturedata_2000))
nobel_literature_2010         <- Corpus(DirSource(literaturedata_2010))

#store speeches by decades in list
nobel_peace_bydecade <- list(
  nobel_peace_1940,
  nobel_peace_1950,
  nobel_peace_1960,
  nobel_peace_1970,
  nobel_peace_1980,
  nobel_peace_1990,
  nobel_peace_2000,
  nobel_peace_2010
)

nobel_literature_bydecade <- list(
  nobel_literature_1940,
  nobel_literature_1950,
  nobel_literature_1960,
  nobel_literature_1970,
  nobel_literature_1980,
  nobel_literature_1990,
  nobel_literature_2000,
  nobel_literature_2010
)

