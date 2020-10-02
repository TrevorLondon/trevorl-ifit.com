library(dplyr)
library(stringr)
library(tidyverse)
install.packages("tidytext")
library(tidytext)
getwd()
df <- read_csv("/Users/trevor.london/NPS_Defactors_Remarks.csv", col_names = TRUE)
str(df)
df %>% 
    select(`Remarks`) %>%
  unnest_tokens(word, `Remarks`) %>%
  count(word, sort = TRUE)

df %>%
  unnest_tokens(word, `Remarks`) %>%
  anti_join(stop_words) %>%
  count(word, sort = TRUE)
# Graph of dist of our word counts. This shows large portions of words appear only once
df %>%
  unnest_tokens(word, `Remarks`) %>%
  anti_join(stop_words) %>%
  count(word) %>%
  ggplot(aes(n)) +
  geom_histogram() +
  scale_x_log10()

#See the low count words
df %>%
  unnest_tokens(word, `Remarks`) %>%
  anti_join(stop_words) %>%
  count(word) %>%
  arrange(n)

#Remove words that only appear once (which are usually misspells, or insignifcant)
df %>%
  unnest_tokens(word, `Remarks`) %>%
  anti_join(stop_words) %>%
  filter (
    !str_detect(word, pattern = "[[:digit:]]"), #removes any words with digits
    !str_detect(word, pattern = "[[:punct:]]"), # removes any remaining punctuations
    !str_detect(word, pattern = "(.)\\1{2,}"),  # removes any words with 3 or more repeated letters
    !str_detect(word, pattern = "\\b(.)\\b")    # removes any remaining single letter words
  ) %>%
  count(word) %>%
  arrange(n)

#Filter for words most frequently used
most_Frequent_words <- df %>%
  unnest_tokens(word, `Remarks`) %>%
  anti_join(stop_words) %>%
  filter(
    !str_detect(word, pattern = "[[:digit:]]"), # removes any words with numeric digits
    !str_detect(word, pattern = "[[:punct:]]"), # removes any remaining punctuations
    !str_detect(word, pattern = "(.)\\1{2,}"),  # removes any words with 3 or more repeated letters
    !str_detect(word, pattern = "\\b(.)\\b")    # removes any remaining single letter words
  ) %>%
  count(word) %>%
  filter(n >= 10) %>% # filter for words used 10 or more times
  arrange(n)
write_clip(most_Frequent_words)
#Stemming. THis gets words down to their root
install.packages("corpus")
library(corpus)
text <- c("love", "loving", "lovingly", "loved", "lovely")
corpus::text_tokens(text, stemmer = "en") %>% unlist()

#Using the stemmed list of love
df %>%
  unnest_tokens(word, `Remarks`) %>%
  anti_join(stop_words) %>%
  filter(
    !str_detect(word, pattern = "[[:digit:]]"), 
    !str_detect(word, pattern = "[[:punct:]]"),
    !str_detect(word, pattern = "(.)\\1{2,}"),  
    !str_detect(word, pattern = "\\b(.)\\b")    
  ) %>%
  mutate(word = corpus::text_tokens(word, stemmer = "en") %>% unlist()) %>% # add stemming process
  count(word) %>% 
  group_by(word) %>%
  summarize(n = sum(n)) %>%
  arrange(desc(n))

# create a vector of all words to keep
word_list <- df %>%
  unnest_tokens(word, `Remarks`) %>%
  anti_join(stop_words) %>%
  filter(
    !str_detect(word, pattern = "[[:digit:]]"), # removes any words with numeric digits
    !str_detect(word, pattern = "[[:punct:]]"), # removes any remaining punctuations
    !str_detect(word, pattern = "(.)\\1{2,}"),  # removes any words with 3 or more repeated letters
    !str_detect(word, pattern = "\\b(.)\\b")    # removes any remaining single letter words
  ) %>%
  count(word) %>%
  filter(n >= 10) %>% # filter for words used 10 or more times
  pull(word)
word_list

# create new features
bow_features <- df %>%
  unnest_tokens(word, `Remarks`) %>%
  anti_join(stop_words) %>%
  filter(word %in% word_list) %>%     # filter for only words in the wordlist
  count(word) %>%                 # count word useage 
  spread(word, n) %>%                 # convert to wide format
  map_df(replace_na, 0)               # replace NAs with 0

bow_features

# join original data and new feature set together (DIDN'T USE THIS AS I DON'T HAVE AN _ID TO JOIN BACK ON)
df_bow <- df %>%
  inner_join(bow_features, by = "ID") %>%   # join data sets
  select(-`Review Text`)                    # remove original review text

# dimension of our new data set
dim(df_bow)
## [1] 22640  2839

as_tibble(df_bow)

***** N-GRAMS *****
#CREATE TRI GRAMS
df %>%
  unnest_tokens(trigram, `Remarks`, token = "ngrams", n = 3) %>%
  head()
df %>%
  unnest_tokens(fourgram,`Remarks`, token = "ngrams", n = 4) %>%
  head()
# create a vector of all bi-grams to keep 
ngram_list <- df %>%
  unnest_tokens(trigram, `Remarks`, token = "ngrams", n = 3) %>%  
  separate(trigram, c("word1", "word2", "word3"), sep = " ") %>%               
  filter(
    !word1 %in% stop_words$word,                 # remove stopwords from both words in tri-gram
    !word2 %in% stop_words$word,
    !word3 %in% stop_words$word,
    !str_detect(word1, pattern = "[[:digit:]]"), # removes any words with numeric digits
    !str_detect(word2, pattern = "[[:digit:]]"),
    !str_detect(word3, pattern = "[[:digit:]]"),
    !str_detect(word1, pattern = "[[:punct:]]"), # removes any remaining punctuations
    !str_detect(word2, pattern = "[[:punct:]]"),
    !str_detect(word3, pattern = "[[:punct:]]"),
    !str_detect(word1, pattern = "(.)\\1{2,}"),  # removes any words with 3 or more repeated letters
    !str_detect(word2, pattern = "(.)\\1{2,}"),
    !str_detect(word3, pattern = "(.)\\1{2,}"),
    !str_detect(word1, pattern = "\\b(.)\\b"),   # removes any remaining single letter words
    !str_detect(word2, pattern = "\\b(.)\\b"),
    !str_detect(word3, pattern = "\\b(.)\\b")
  ) %>%
  unite("trigram", c(word1, word2, word3), sep = " ") %>%
  count(trigram) %>%
  #filter(n >= 5 %>% # filter for bi-grams used 10 or more times
  pull(trigram)

# sneak peek at our bi-gram list
head(ngram_list)
ngram_list


# create new bi-gram features
ngram_features <- df %>%
  unnest_tokens(trigram, `Remarks`, token = "ngrams", n = 3) %>%
  filter(trigram %in% ngram_list) %>%    # filter for only bi-grams in the ngram_list
  count(trigram) %>%                 # count bi-gram useage by customer ID
  spread(trigram, n) %>%                 # convert to wide format
  map_df(replace_na, 0)                 # replace NAs with 0

ngram_features
write_csv(ngram_features, "/Users/trevor.london/NPS_ngram_Remarks.csv", append = FALSE)

#Doing bi-grams 
df %>%
  unnest_tokens(trigram, `Remarks`, token = "ngrams", n = 2) %>%
  head()

ngram_list <- df %>%
  unnest_tokens(bigram, `Remarks`, token = "ngrams", n = 2) %>%  
  separate(bigram, c("word1", "word2"), sep = " ") %>%               
  filter(
    !word1 %in% stop_words$word,                 # remove stopwords from both words in tri-gram
    !word2 %in% stop_words$word,
    !str_detect(word1, pattern = "[[:digit:]]"), # removes any words with numeric digits
    !str_detect(word2, pattern = "[[:digit:]]"),
    !str_detect(word1, pattern = "[[:punct:]]"), # removes any remaining punctuations
    !str_detect(word2, pattern = "[[:punct:]]"),
    !str_detect(word1, pattern = "(.)\\1{2,}"),  # removes any words with 3 or more repeated letters
    !str_detect(word2, pattern = "(.)\\1{2,}"),
    !str_detect(word1, pattern = "\\b(.)\\b"),   # removes any remaining single letter words
    !str_detect(word2, pattern = "\\b(.)\\b")
  ) %>%
  unite("bigram", c(word1, word2), sep = " ") %>%
  count(bigram) %>%
  #filter(n >= 5 %>% # filter for bi-grams used 10 or more times
  pull(bigram)

# sneak peek at our bi-gram list
head(ngram_list)
ngram_list

# create new bi-gram features
ngram_features <- df %>%
  unnest_tokens(bigram, `Remarks`, token = "ngrams", n = 2) %>%
  filter(bigram %in% ngram_list) %>%    # filter for only bi-grams in the ngram_list
  count(bigram) %>%                 # count bi-gram useage by customer ID
  spread(bigram, n) %>%                 # convert to wide format
  map_df(replace_na, 0)                 # replace NAs with 0

ngram_features
write_csv(ngram_features, "/Users/trevor.london/NPS_ngram_bigram_Remarks.csv", append = FALSE)

bigrams <- df %>%
  select(`Remarks`) %>%
  unnest_tokens(bigram, `Remarks`, token = "ngrams", n=2) %>%
  filter(bigram %in% ngram_list) %>%
  separate(bigram, c("word1", "word2"), sep = " ")

head(bigrams)
count_w1 <- bigrams %>%
  count(word1)
count_w2 <- bigrams %>%
  count(word2)
count_w12 <- bigrams %>%
  count(word1,word2)
count_w12

#compute log-likelihood
N <- nrow(bigrams)
LL_test <- count_w12 %>%
  left_join(count_w1, by ="word1") %>%
  left_join(count_w2, by ="word2") %>%
  rename(c_w1 = n.y, c_w2 = n, c_w12 = n.x) %>%
  mutate(
    p = c_w2/ N,
    p1 = c_w12 / c_w1,
    p2 = (c_w2 - c_w12) / (N - c_w1),
    LL = log((pbinom(c_w12, c_w1, p) * pbinom(c_w2 - c_w12, N - c_w1, p)) / (pbinom(c_w12, c_w1, p1) * pbinom(c_w2 - c_w12, N - c_w1, p)))
  )
LL_test
write_csv(LL_test, "/Users/trevor.london/NPS_log_likelihoods.csv", append = FALSE)
#This generates a list where word2 is strongly correlated to word 1
unique_bigrams <- LL_test %>%
  mutate(
    Chi_value = -2 * LL,
    pvalue = pchisq(LL, df = 1)
  ) %>%
  filter(pvalue < 0.05) %>%
  select(word1, word2) %>%
  unite(bigram, word1, word2, sep = " ")

unique_bigrams
write_csv(unique_bigrams, "/Users/trevor.london/NPS_strongly_correlated_words.csv", append = FALSE)

#doing this on trigrams to try to find what precedes customer service
tri_ngram_list <- df %>%
  unnest_tokens(trigram, `Remarks`, token = "ngrams", n = 3) %>%  
  separate(trigram, c("word1", "word2", "word3"), sep = " ") %>%               
  filter(
    !word1 %in% stop_words$word,                 # remove stopwords from both words in tri-gram
    !word2 %in% stop_words$word,
    !word3 %in% stop_words$word,
    !str_detect(word1, pattern = "[[:digit:]]"), # removes any words with numeric digits
    !str_detect(word2, pattern = "[[:digit:]]"),
    !str_detect(word3, pattern = "[[:digit:]]"),
    !str_detect(word1, pattern = "[[:punct:]]"), # removes any remaining punctuations
    !str_detect(word2, pattern = "[[:punct:]]"),
    !str_detect(word3, pattern = "[[:punct:]]"),
    !str_detect(word1, pattern = "(.)\\1{2,}"),  # removes any words with 3 or more repeated letters
    !str_detect(word2, pattern = "(.)\\1{2,}"),
    !str_detect(word3, pattern = "(.)\\1{2,}"),
    !str_detect(word1, pattern = "\\b(.)\\b"),   # removes any remaining single letter words
    !str_detect(word2, pattern = "\\b(.)\\b"),
    !str_detect(word3, pattern = "\\b(.)\\b")
  ) %>%
  unite("trigram", c(word1, word2, word3), sep = " ") %>%
  count(trigram) %>%
  #filter(n >= 10) %>% # filter for bi-grams used 10 or more times
  pull(trigram)
head(tri_ngram_list)
trigrams <- df %>%
  select(`Remarks`) %>%
  unnest_tokens(trigram, `Remarks`, token = "ngrams", n = 3) %>%  
  filter(trigram %in% tri_ngram_list) %>%
  separate(trigram, c("word1", "word2", "word3"), sep = " ")

trigrams
count_w1 <- trigrams %>%
  count(word1)
count_w2 <- trigrams %>%
  count(word2)
count_w3 <- trigrams %>%
  count(word3)
count_w123 <- trigrams %>%
  count(word1,word2,word3)
count_w123
write_csv(count_w123, "/Users/trevor.london/NPS_trigrams_counts.csv", append = FALSE)
N <- nrow(trigrams)
LL_test_tri <- count_w123 %>%
  left_join(count_w1, by ="word1") %>%
  left_join(count_w2, by ="word2") %>%
  left_join(count_w3, by ="word3") %>%
  rename(c_w1 = n.y, c_w2 = n.x, c_w3 = n.x.x, c_w123 = n.y.y)
LL_test_tri

#Trying with 4grams
fourgram_list <- df %>%
  unnest_tokens(fourgram, `Remarks`, token = "ngrams", n = 4) %>%  
  separate(fourgram, c("word1", "word2", "word3", "word4"), sep = " ") %>%               
  filter(
    !word1 %in% stop_words$word,                 # remove stopwords from both words in tri-gram
    !word2 %in% stop_words$word,
    !word3 %in% stop_words$word,
    !word4 %in% stop_words$word,
    !str_detect(word1, pattern = "[[:digit:]]"), # removes any words with numeric digits
    !str_detect(word2, pattern = "[[:digit:]]"),
    !str_detect(word3, pattern = "[[:digit:]]"),
    !str_detect(word4, pattern = "[[:digit:]]"),
    !str_detect(word1, pattern = "[[:punct:]]"), # removes any remaining punctuations
    !str_detect(word2, pattern = "[[:punct:]]"),
    !str_detect(word3, pattern = "[[:punct:]]"),
    !str_detect(word4, pattern = "[[:punct:]]"),
    !str_detect(word1, pattern = "(.)\\1{2,}"),  # removes any words with 3 or more repeated letters
    !str_detect(word2, pattern = "(.)\\1{2,}"),
    !str_detect(word3, pattern = "(.)\\1{2,}"),
    !str_detect(word4, pattern = "(.)\\1{2,}"),
    !str_detect(word1, pattern = "\\b(.)\\b"),   # removes any remaining single letter words
    !str_detect(word2, pattern = "\\b(.)\\b"),
    !str_detect(word3, pattern = "\\b(.)\\b"),
    !str_detect(word4, pattern = "\\b(.)\\b")
  ) %>%
  unite("fourgram", c(word1, word2, word3, word4), sep = " ") %>%
  count(fourgram) %>%
  #filter(n >= 10) %>% # filter for bi-grams used 10 or more times
  pull(fourgram)
head(fourgram_list)

fourgrams <- df %>%
  select(`Remarks`) %>%
  unnest_tokens(fourgram, `Remarks`, token = "ngrams", n = 4) %>%  
  filter(fourgram %in% fourgram_list) %>%
  separate(fourgram, c("word1", "word2", "word3", "word4"), sep = " ")

fourgrams
count_w1 <- fourgrams %>%
  count(word1)
count_w2 <- fourgrams %>%
  count(word2)
count_w3 <- fourgrams %>%
  count(word3)
count_w4 <- fourgrams %>%
  count(word4)
count_w1234 <- fourgrams %>%
  count(word1,word2,word3,word4)
count_w1234
write_csv(count_w1234, "/Users/trevor.london/NPS_fourgrams_counts.csv", append = FALSE)

#Getting Words that preced 
trigrams %>%
  filter(word1 == "worst") %>%
  count(word1, word2, sort = TRUE)
AFINN <- get_sentiments("afinn")
AFINN
#Getting Words that preced "Customer"
not_words <- trigrams %>%
  filter(word2 == "customer") %>%
  inner_join(AFINN, by =c(word1 = "word")) %>%
  count(word1, value, sort = TRUE) %>%
  ungroup()
not_words
trigrams

cs_words <- trigrams %>%
  filter(word2 == "service") %>%
  inner_join(AFINN, by =c(word1 = "word")) %>%
  count(word3, value, sort = TRUE) %>%
  ungroup()
cs_words
trigrams

library(sqldf)
sqldf("select word1, word2, word3, count(*) from trigrams where word1 like '%customer%' AND word2 like '%service%'")

cs_sentences <- sqldf("select * from df0 where sentence like '%customer%' and sentence like '%service%'")
equip_sentences <- sqldf("select * from df0 where sentence like '%equipment%'")
software_sentences <- sqldf("select * from df0 where sentence like '%software%'")
cost_sentences <- sqldf("select * from df0 where sentence like '%cost%' or sentence like '%expensive%' or sentence like '%price%'")
library(clipr)
write_clip(cs_sentences)
write_clip(equip_sentences)
write_clip(software_sentences)
write_clip(cost_sentences)
df0
df_query <- df0 %>% 
  select(`sentence`) %>%
  unnest_tokens(word, `sentence`) %>%
  anti_join(stop_words) %>%
  count(word, sort = TRUE)
df_query


library(tidytext)
install.packages("textdata")
library(textdata)
1
1
# CREATING A DF WITH 1 WORD PER ROW
 one_word_df <- df %>% 
  select(`Remarks`) %>%
  unnest_tokens(word, `Remarks`)

# CREATING DF OF "NEGATIVE" SENTIMENT WORDS FROM THE NRC SOURCE
nrc_negative <- get_sentiments("nrc") %>%
  filter(sentiment == "negative")
#JOINING MY DF WITH THE NEGATIVE WORDS NRC DF TO GET RESULTING COUNTS OF NEGATIVE WORDS
negative_words <- one_word_df %>%
  inner_join(nrc_negative) %>%
  count(word, sort = TRUE)
write_csv(negative_words, "/Users/trevor.london/NPS_negative_words.csv", append = FALSE)
#Seeing a "select sentiment, count(*) group by sentiment" look
get_sentiments("nrc") %>% group_by(sentiment) %>% tally()

#CREATING A "POSITIVE" SENTIMENT DF NOW 
nrc_positive <- get_sentiments("nrc") %>%
  filter(sentiment == "positive")

positive_words <- one_word_df %>%
  inner_join(nrc_positive) %>%
  count(word, sort = TRUE)
positive_words

#creating graph of top 10 negative words
negative_words %>%
  top_n(10) %>%
  #mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n, fill = word)) +
  geom_col(show.legend = FALSE) +
  #facet_wrap(~sentiment, scales = "free_y") +
  labs(y = "Contribution to Sentiment",
       x = NULL) +
  coord_flip()

*** Wordcloud ***
install.packages("wordcloud")
library(wordcloud)

negative_words %>%
  count(word) %>%
  with(wordcloud(word, n, max.words = 25))

install.packages("topicmodels")
library(topicmodels)

df_bigrams <- df %>%
  unnest_tokens(bigram, `Remarks`, token = "ngrams", n = 2)
bigrams_separated <- df_bigrams %>%
  separate(bigram, c("word1", "word2"), sep = " ")

bigrams_filtered <- bigrams_separated %>%
  filter(!word1 %in% stop_words$word) %>%
  filter(!word2 %in% stop_words$word) 

bigram_counts <- bigrams_filtered %>%
  count(word1, word2, sort = TRUE)

bigram_counts


# Getting a DF with sentences from original
df0 <- df %>%
    unnest_tokens(
    output = sentence,
    input = `Remarks`,
    token = 'sentences'
  )
df0
df02 <- df %>%
  unnest_tokens(
    output = sentence,
    input = `Remarks`,
    token = 'sentences',
    filter(stop_words)
  )
#Tokenize to the word level along with creating sentence_ids 
df_tokenized <- df %>%
  mutate(sentence_id = 1:n()) %>%
  unnest_tokens(
    output = word,
    input = `Remarks`,
    token = 'words',
    drop = FALSE
  ) %>%
  ungroup()

#Numeric-based lexicon sentiment score per sentence
install.packages("sentimentr")
library(sentimentr)
df_sentiment <- df0 %>%
  get_sentences(text) %>%
  sentiment() %>%
  drop_na() %>%
  mutate(sentence_id = row_number())
df_sentiment
write_csv(df_sentiment, "/Users/trevor.london/NPS_Sentiment_Scores.csv", append = FALSE)

#plotting df_sentiment
install.packages("plotly")
library(plotly)

hist(df_sentiment$sentiment, main = 'Sentiment Polarity Distribution', 
     xlab = 'Polarity',
     ylab = 'Count',
     col = 'Red',
     border = 'Black')

#Topic Modeling
library(topicmodels)
df_stemmed <- df %>%
  unnest_tokens(word, `Remarks`) %>%
  anti_join(stop_words) %>%
  filter(
    !str_detect(word, pattern = "[[:digit:]]"), 
    !str_detect(word, pattern = "[[:punct:]]"),
    !str_detect(word, pattern = "(.)\\1{2,}"),  
    !str_detect(word, pattern = "\\b(.)\\b")    
  ) %>%
  mutate(word = corpus::text_tokens(word, stemmer = "en") %>% unlist()) # add stemming process
library(tm)
files <- read_csv("/Users/trevor.london/NPS_ngram_bigram_Remarks.csv",col_names = TRUE)
df_corpus <- VCorpus(VectorSource(files))
print(df_corpus)
lapply(df_corpus[1:2], as.character)
df_corpus_clean <- tm_map(df_corpus, content_transformer(tolower))
df_corpus_clean <- tm_map(df_corpus_clean, removeNumbers)
df_corpus_clean <- tm_map(df_corpus_clean, removeWords, stopwords())
df_corpus_clean <- tm_map(df_corpus_clean, removePunctuation)
df_corpus_clean <- tm_map(df_corpus_clean, stemDocument)
df_corpus_clean <- tm_map(df_corpus_clean, stripWhitespace)
#Creating a DTM sparse matrix
df_dtm <- DocumentTermMatrix(df_corpus)
df_dtm
df_dtm_train <- df_dtm[1:1200, ]
df_dtm_test <- df_dtm[1201:1430, ]
AssociatedPress
df_dtm
df_dtm_topic_model <- LDA(df_dtm, k=10, control = list(seed = 321))


