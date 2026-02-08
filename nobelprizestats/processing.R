#nobelprize analysis with statistical techniques.
#explorative analysis, including machine learning, quantitative text analysis.
#processing and computation

#### min variables for analysis
#plotting frame for all nobel prizes
years          <- seq(1940, 2010, 10)
frequencies    <- c(1:length(years))
numberofwords  <- 5


### key functions used
#select the most frequent words out of corpus.
frequentwordsincorpus <- function (x)
{
  
  #all speeches
  nobel_prize    <- x
  
  #preprocessing
  #remove number, capitalisation, common words, puntucation, other meaningless bits.
  nobel_prize  <- tm_map(nobel_prize, removePunctuation)
  nobel_prize  <- tm_map(nobel_prize, removeNumbers)
  nobel_prize  <- tm_map(nobel_prize, tolower)#lowercase
  nobel_prize  <- tm_map(nobel_prize, removeWords, stopwords("english"))
  nobel_prize  <- tm_map(nobel_prize, stemDocument)
  nobel_prize  <- tm_map(nobel_prize, stripWhitespace)
 # nobel_prize  <- tm_map(nobel_prize, PlainTextDocument)
 
  #stage the data
  dtm   <- DocumentTermMatrix(nobel_prize)
  tdm   <- TermDocumentMatrix(nobel_prize)
  
  #removing sparse terms
  dtms  <- removeSparseTerms(dtm, 0.1)
  
  #Clustering by Term Similarity
  dtmss <- removeSparseTerms(dtm, 0.15) # This makes a matrix that is only 15% empty space, maximum.
  
  #findFreqTerms(dtms, lowfreq=50)
  freq  <- colSums(as.matrix(dtms))
  freq
  freq  <- sort(colSums(as.matrix(dtm)), decreasing = TRUE)
  wf    <- data.frame(word = names(freq), freq = freq)
  
  #frequencies are key outcome of the pre-processing
  mostfrequentwords50                <- wf[1:50,]
  #mostfrequentwords15               <- freq[tail(ord)]
  
  return(mostfrequentwords50)
}

#matrix with top words x years in decades
compute_word_frequencies_topfive_byyear <- function (x) {
  
  #dataframe empty to be filled
  word_frequencies_topfive_byyear           <- data.frame(matrix(0, ncol = 8, nrow = length(x)), row.names = x)
  colnames(word_frequencies_topfive_byyear) <- years
  
  #fill datafran
  for (i in 1:length(nobel_peace_bydecade)) {
    count       <- i
    nobel_prize <- nobel_peace_bydecade[[count]]
    
    mostfrequentwords <- frequentwordsincorpus(nobel_prize)
    
    #create entries of each word(row) for each decade
    for (j in x) {
      # count+1 since the first oclumn is the word
      word_frequencies_topfive_byyear[j, count]     <- mostfrequentwords[j, 'freq']
    }
  }
  #goal is dataframe of frequencies
  return(word_frequencies_topfive_byyear)
}

########################  Processing data ###########

#Part A: all speeches
#all speeches, most frequent words
peace_mostfrequentwords50      <- frequentwordsincorpus(nobel_peace)
literature_mostfrequentwords50 <- frequentwordsincorpus(nobel_literature)

#Part B: Sub-analysis for frequencies by decade
#most frequent words for prize overall through whole history
peace_word_frequencies_topfive        <- as.character(peace_mostfrequentwords50$word[1:numberofwords])
literature_frequencies_topfive        <- as.character(literature_mostfrequentwords50$word[1:numberofwords])

#setup matrices word x decades
peace_word_by_decades      <- compute_word_frequencies_topfive_byyear(peace_word_frequencies_topfive)
literature_word_by_decades <- compute_word_frequencies_topfive_byyear(literature_frequencies_topfive)

#dataframe for plotting in ggvis package
peace_word_frequencies_topfive        <- data.frame(t(peace_word_by_decades))
peace_word_frequencies_topfive$years  <- rownames(peace_word_frequencies_topfive)
peace_column_names                    <- c(names(peace_word_frequencies_topfive))
literature_word_frequencies_topfive        <- data.frame(t(literature_word_by_decades))
literature_word_frequencies_topfive$years  <- rownames(literature_word_frequencies_topfive)
literature_column_names               <- c(names(literature_word_frequencies_topfive))

#scatterplotmatrix, drop the 'years' string
pairs.panels(peace_word_frequencies_topfive[ , - 6])
pairs.panels(literature_word_frequencies_topfive[ , - 6])


#########Part C: Sentiment analysis in future
# Sentiment analysis[edit]
# Sentiment analysis may involve analysis of movie reviews for estimating how favorable a review is for a movie.[20] Such an analysis may need a labeled data set or labeling of the affectivity of words. Resources for affectivity of words and concepts have been made for WordNet[21] and ConceptNet,[22] respectively.
#
# # Text has been used to detect emotions in the related area of affective computing.[23] Text based approaches to affective computing have been used on multiple corpora such as students evaluations, children stories and news stories.
# install.packages('syuzhet')
# library('syuzhet')
#
# get_dct_transform(dtm, low_pass_size = 5, x_reverse_len = 100, scale_vals = FALSE, scale_range = FALSE)
#
# str(nobel_literature)
# head(nobel_literature)
# get_nrc_sentiment(nobel_literature)

### end of processing 

#### Plotting all 

#plot
peace_word_frequencies_topfive %>% ggvis(~years, ~peace_word_frequencies_topfive[ , 1]) %>% layer_lines(stroke = literature_column_names[1]) %>% add_axis("x", title = "Importance of words in peace nobel prize for peace speeches(by decades)") %>% add_axis("y", title = "Word frequency") %>% layer_paths(y = ~peace_word_frequencies_topfive[ , 2], stroke = literature_column_names[2]) %>% layer_paths(y = ~peace_word_frequencies_topfive[ , 3], stroke = literature_column_names[3]) %>% layer_paths(y = ~peace_word_frequencies_topfive[ , 4], stroke = literature_column_names[4]) %>% layer_paths(y = ~peace_word_frequencies_topfive[ , 5], stroke = literature_column_names[5])

pairs.panels(peace_word_frequencies_topfive[ , - 6])

