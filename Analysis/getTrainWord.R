library(stringr)

# get words and their frequencies from newtrain_exp.txt 
te <- readLines("newtrain_exp.txt")
head(te, 50)

word <- str_extract(te,  "Word: ([a-z]+)")
word <- str_replace(word, "Word: ", "")
wordloc <- which(!is.na(word))
wordList <- c()
for (ll in rev(wordloc)) {
  print(ll)
  wordList <- c(wordList, word[ll])
}

prob <- str_extract(te,  "PROB ([0-9.]+)")
prob <- str_replace(prob, "PROB ", "")
probloc <- which(!is.na(prob))
probList <- c()
for (ll in rev(probloc)) {
  print(ll)
  probList <- c(probList, prob[ll])
}

DF <- data.frame(word=wordList, prob=as.numeric(probList))
DF <- DF[sort(DF$word, decreasing=TRUE),]
write.csv(DF, "WordList.csv", row.names=FALSE)