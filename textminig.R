library(dplyr)
library(stats)
library(tidytext)
library(gtools) # if problems calling library, install.packages("gtools", dependencies = T)
library(qdap) # qualitative data analysis package (it masks %>%)
library(tm) # framework for text mining; it loads NLP package
library(Rgraphviz) # depict the terms within the tm package framework
library(SnowballC); library(RWeka); library(rJava); library(RWekajars)  # wordStem is masked from SnowballC
library(Rstem) # stemming terms as a link from R to Snowball C stemmer
#install.packages("Rstem", repos = "http://www.omegahat.org/R")
#install.packages("rJava", type = "source")
#install.packages("openNLP")
#require(rJava)
#require(openNLP)
library(rJava)
library(openNLP)
require(quanteda)
help(corpus)


getwd()
details<-read.csv('data/jobdetails.csv')
summary(details)


test<-details$X4_jobdetials
test <- gsub("'", "", test) # remove apostrophes
test <- gsub("[[:punct:]]", " ", test)  # replace punctuation with space
test <- gsub("[[:cntrl:]]", " ", test)  # replace control characters with space
test <- gsub("^[[:space:]]+", "", test) # remove whitespace at beginning of documents
test <- gsub("[[:space:]]+$", "", test) # remove whitespace at end of documents
test <- gsub("[^a-zA-Z -]", " ", test) # allows only letters
test <- tolower(test)  # force to lowercase
## get rid of blank docs
test <- test[test != ""]

# tokenize on space and output as a list:
test.list <- strsplit(test, "[[:space:]]+")
test.list
# compute the table of terms:
test.table <- table(unlist(test.list))
test.table <- sort(test.table, decreasing = TRUE)

#add new stopword files 
#new_stop<-readLines('Desktop/project/LinkedinData/data/minimal-stop.txt')
new<-read.table('data/minimal-stop.txt',sep="\n", 
                fill=FALSE, 
                strip.white=TRUE)

#stop<-toString(new$V1)
#stop<-unlist(new$V1)
stop<-as.character(new$V1)


# remove terms that are stop words or occur fewer than 5 times:
del <- names(test.table) %in% stop | test.table < 5
test.table <- test.table[!del]
test.table <- test.table[names(test.table) != ""]
vocab <- names(test.table)

# now put the documents into the format required by the lda package:
get.terms <- function(x) {
  index <- match(x, vocab)
  index <- index[!is.na(index)]
  rbind(as.integer(index - 1), as.integer(rep(1, length(index))))
}
test.documents <- lapply(test.list, get.terms)
test.documents


#############
# Compute some statistics related to the data set:
D <- length(test.documents)  # number of documents (1)
W <- length(vocab)  # number of terms in the vocab (1741)
test.length <- sapply(test.documents, function(x) sum(x[2, ]))  # number of tokens per document [312, 288, 170, 436, 291, ...]
N <- sum(test.length)  # total number of tokens in the data (56196)
test.frequency <- as.integer(test.table) 

# MCMC and model tuning parameters:
K <- 10
G <- 3000
alpha <- 0.02
eta <- 0.02

# Fit the model:
library(lda)
set.seed(357)
t1 <- Sys.time()
fit <- lda.collapsed.gibbs.sampler(documents = test.documents, K = K, vocab = vocab, 
                                   num.iterations = G, alpha = alpha, 
                                   eta = eta, initial = NULL, burnin = 0,
                                   compute.log.likelihood = TRUE)
t2 <- Sys.time()

## display runtime
t2 - t1  

theta <- t(apply(fit$document_sums + alpha, 2, function(x) x/sum(x)))
phi <- t(apply(t(fit$topics) + eta, 2, function(x) x/sum(x)))

news_for_LDA <- list(phi = phi,
                     theta = theta,
                     doc.length = test.length,
                     vocab = vocab,
                     term.frequency = test.frequency)

library(LDAvis)
library(servr)

# create the JSON object to feed the visualization:
json <- createJSON(phi = news_for_LDA$phi, 
                   theta = news_for_LDA$theta, 
                   doc.length = news_for_LDA$doc.length, 
                   vocab = news_for_LDA$vocab, 
                   term.frequency = news_for_LDA$term.frequency)

serVis(json, out.dir = 'vis', open.browser = TRUE)

###
test <- tolower(test)
job_corpus<-corpus(test)
#explore the corpus
names(job_corpus)
summary(job_corpus)
head(job_corpus)

#clean corpus: removes punctuation, digits, converts to lower case
help(tokenize)
help(tolower)
cleancorpus <- tokenize(job_corpus, 
                        removeNumbers=TRUE,  
                        removePunct = TRUE,
                        removeSeparators=TRUE,
                        removeTwitter=FALSE,
                        verbose=TRUE)

#explore the clean corpus
head(cleancorpus)    # text into token form

#create document feature matrix from clean corpus + stem
help(dfm)
dfm.simple<- dfm(cleancorpus,
                 toLower = TRUE, 
                 ignoredFeatures =stopwords("english"), 
                 remove=stop,
                 verbose=TRUE, 
                 stem=FALSE)
head(dfm.simple) #explore output of dfm

#to display most frequent terms in dfm
topfeatures<-topfeatures(dfm.simple, n=100)
topfeatures

#to create a custom dictionary  list of stop words
addlist = c("including", "other", "all",'related','years','more','well','within','include',
            "the","with","a","in","will","be","of","data")
dfm.stem<- dfm(cleancorpus, toLower = TRUE, 
               ignoredFeatures = c(addlist, stopwords("english")),
               verbose=TRUE, 
               remove=c(stop,addlist),
               stem=TRUE)
topfeatures.stem<-topfeatures(dfm.stem, n=50)
topfeatures.stem

#exploration in context
kwic(cleancorpus, "programming", 2)
kwic(cleancorpus , "data", window = 2)
kwic(cleancorpus , "analysis", window = 2)

#dfm with bigrams
help("tokenize")
cleancorpus <- tokenize(job_corpus,  
                        removeNumbers=TRUE,  
                        removePunct = TRUE,
                        removeSeparators=TRUE,
                        remove_symbols=TRUE,
                        removeTwitter=FALSE, 
                        ngrams=2, verbose=TRUE)
cleancorpus
dfm.bigram<- dfm(cleancorpus, toLower = TRUE, 
                 ignoredFeatures = c(addlist, stopwords("english")),
                 remove=stop,
                 verbose=TRUE, 
                 stem=FALSE)
topfeatures.bigram<-topfeatures(dfm.bigram, n=50)
topfeatures.bigram

#Sentiment Analysis
help(dfm)
mydict <- dictionary(list(negative = c("detriment*", "bad*", "awful*", "terrib*", "horribl*"),
                          postive = c("good", "great", "super*", "excellent", "yay")))
dfm.sentiment <- dfm(cleancorpus, dictionary = mydict)
topfeatures(dfm.sentiment)
View(dfm.sentiment)


#########################
### WORD CLOUD ########
#########################


library(wordcloud)
library(RColorBrewer)
set.seed(142)   #keeps cloud' shape fixed
dark2 <- brewer.pal(8, "Set1")   
freq<-topfeatures(dfm.stem, n=500)

help("wordcloud")
wordcloud(names(freq), 
          freq, max.words=200, 
          scale=c(3, .1), 
          colors=brewer.pal(8, "Set1"))


#specifying a correlation limit of 0.5  
library(stm)
library(tm)
help(findAssocs)
dfm.tm<-convert(dfm.stem, to="tm")
findAssocs(dfm.tm, 
           c("analysis", "big","model","statistics"), 
           corlimit=0.5)
findAssocs(dfm.tm, 
           c("process","cooperate", "implement" ), 
           corlimit=0.4)

##########################
### Topic Modeling
##########################

library(stm)

#Process the data for analysis.
help("textProcessor")
temp<-textProcessor(documents=details$X4_jobdetials, metadata = details)
names(temp)  # produces:  "documents", "vocab", "meta", "docs.removed" 
meta<-temp$meta
vocab<-temp$vocab
docs<-temp$documents
out <- prepDocuments(docs, vocab, meta)
docs<-out$documents
vocab<-out$vocab
meta <-out$meta


#running stm for top 20 topics
help("stm")
prevfit <-stm(docs , vocab , 
              K=20, 
              verbose=TRUE,
              data=meta, 
              max.em.its=25)

topics <-labelTopics(prevfit , topics=c(1:20))
topics   #shows topics with highest probability words

#explore the topics in context.  Provides an example of the text 
help("findThoughts")
findThoughts(prevfit, texts = details$X4_jobdetials,  topics = 10,  n = 2)

help("plot.STM")
plot.STM(prevfit, type="summary")
plot.STM(prevfit, type="labels", topics=c(15,4,5))
plot.STM(prevfit, type="perspectives", topics = c(19,10))

# to aid on assigment of labels & intepretation of topics
help(topicCorr)
library(NLP)
library(openNLP)
mod.out.corr <- topicCorr(prevfit)  #Estimates a graph of topic correlations
plot.topicCorr(mod.out.corr)


data_filter<-
  data%>%dplyr::filter(details$X4_jobdetials!='None')

job_corpus<-Corpus(VectorSource(data_filter$X4_jobdetials))
inspect(job_corpus[1:3])
stop_words<-c(stopwords(kind='en'),stop,'will')
stop_words

clean_corpus<-tm_map(job_corpus, tolower)
clean_corpus <- tm_map(clean_corpus, removeNumbers)
#remove contractions--  expand all contractions to their "formal English" equivalents: don't to do not, we'll to we will, etc.
clean_corpus <- tm_map(clean_corpus, fix_contractions)
clean_corpus <- tm_map(clean_corpus, removePunctuation)
clean_corpus <- tm_map(clean_corpus, removeWords,stop_words)
#remove the excess white space
clean_corpus <- tm_map(clean_corpus, stripWhitespace)
#keep the stem of the word, in order to make sure working/worked/worker will be in the same class
clean_corpus<-tm_map(clean_corpus, stemDocument, language = "english") 

inspect(clean_corpus[1:3])
# tokenize the corpus
job_details <- DocumentTermMatrix(clean_corpus)
findFreqTerms(job_details,250)
findAssocs(job_details,'skills',0.3)
########### DTM 
###keep the short word out 
dtm <- DocumentTermMatrix(clean_corpus,control=list(wordLengths=c(4, 20)))
dtm    # This is a 547 x 11358 dimension matrix in which 98% of the rows are zero.
#get the frequency of occurrence of each word in the corpus
freq <- colSums(as.matrix(dtm))
#sort freq in descending order of term count:
ord <- order(freq,decreasing=TRUE)
#inspect most frequently occurring terms
freq[ord[1:200]]

#######term document matrix
tdm<-TermDocumentMatrix(clean_corpus)
tdm_new<-as.matrix(tdm)
tdm_new

#tdm_new<-inspect(tdm)
Freq<-rowSums(tdm_new)
Freq_order<-order(Freq,decreasing=TRUE)
Freq[Freq_order[1:50]]

####################  co-occurance
findFreqTerms(dtm,lowfreq=300)
findAssocs(dtm,"data",0.4)
findAssocs(dtm,"project",0.3)
findAssocs(dtm,"skill",0.2)
findAssocs(dtm,"analysis",0.4)

#######graphics

wf=data.frame(term=names(freq),occurrences=freq)
library(ggplot2)
p <- ggplot(subset(wf, freq>300), aes(term, occurrences))
p <- p + geom_bar(stat='identity')
p <- p + theme(axis.text.x=element_text(angle=45, hjust=1))
p<-p+ggtitle("Demanded skillset in data analyst positions",position='Center')
p
#wordcloud
library(wordcloud)
#setting the same seed each time ensures consistent look across clouds
set.seed(42)
#limit words by specifying min frequency
wordcloud(names(freq),freq, min.freq=200,max.freq=900)
