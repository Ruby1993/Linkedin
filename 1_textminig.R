library(dplyr)
library(tidytext)
library(gtools) # if problems calling library, install.packages("gtools", dependencies = T)
library(qdap) # qualitative data analysis package (it masks %>%)
library(tm) # framework for text mining; it loads NLP package
library(Rgraphviz) # depict the terms within the tm package framework
library(SnowballC); library(RWeka); library(rJava); library(RWekajars)  # wordStem is masked from SnowballC
library(Rstem) # stemming terms as a link from R to Snowball C stemmer
details<-read.csv('Desktop/project/LinkedinData/data/jobdetails.csv')
summary(details)
#add new stopword files 
#new_stop<-readLines('Desktop/project/LinkedinData/data/minimal-stop.txt')
new<-read.table('Desktop/project/LinkedinData/data/minimal-stop.txt',sep="\n", 
                fill=FALSE, 
                strip.white=TRUE)

#stop<-toString(new$V1)
#stop<-unlist(new$V1)
stop<-as.character(new$V1)

data_filter<-data%>%
  filter(details$X4_jobdetials!='None',)

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
freq[ord[1:50]]

#######term document matrix
tdm<-TermDocumentMatrix(clean_corpus)
tdm_new<-as.matrix(tdm)
tdm_new

#tdm_new<-inspect(tdm)
Freq<-rowSums(tdm_new)
Freq_order<-order(Freq,decreasing=TRUE)
Freq[Freq_order[1:50]]

####################  co-occurance
findFreqTerms(dtm,lowfreq=500)
findAssocs(dtm,"data",0.5)
findAssocs(dtm,"project",0.3)
findAssocs(dtm,"skill",0.3)
findAssocs(dtm,"analysis",0.5)

#######graphics

wf=data.frame(term=names(freq),occurrences=freq)
library(ggplot2)
p <- ggplot(subset(wf, freq>300), aes(term, occurrences))
p <- p + geom_bar(stat='identity')
p <- p + theme(axis.text.x=element_text(angle=45, hjust=1))
p

#wordcloud
library(wordcloud)
#setting the same seed each time ensures consistent look across clouds
set.seed(42)
#limit words by specifying min frequency
wordcloud(names(freq),freq, min.freq=300,max.freq=600)
