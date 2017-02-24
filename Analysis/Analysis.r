library(stringr)
library(reshape2)
library(tidyr)
library(ggplot2)
library(hexbin)
library(plyr)
library(Rmisc)

options(max.print=10000)
drawrange <- c(1e4,1e7); errrange_ptop <- c(10, 1e7); errrange_otop <- c(10, 1e7)
scinot <- function(x){
  if(is.numeric(x)){ format(x, scientific=TRUE)
  }else{ error("x must be numeric") }
}
figDir <- './figure/'
dir.create(figDir)

##################################################
# read from TrEm.txt
getList <- function(te, exp1, exp2){
  raw <- str_extract(te, exp1); raw <- str_replace(raw, exp2, "")
  rawLoc <- which(!is.na(raw))
  rawList <- c()
  for(ll in rawLoc){
    rawList <- c(rawList, raw[ll])
  }
  return(rawList)
}
crtDF <- function(t){
  wordList <- getList(t, "Word: ([a-z\"]+)", "Word: ") # get words
  probList <- getList(t, "PROB ([0-9.]+)", "PROB ") # get probs
  phonoList <- getList(t, "Rep_P: ([_/a-zA-Z@&^]+)", "Rep_P: ") # get phonological representations
  orthoList <- getList(t, "Rep_O: ([_/a-zA-Z]+)", "Rep_O: ") # get orthographical representations
  P <- str_replace_all(phonoList, "(_|/)", "")
  OPList <- paste(wordList, P, sep=".") # create OP list
  cat('noPh: ', length(unique(wordList)), '; noUniqueP: ', length(unique(P)),'; noOP: ', length(unique(OPList)), '\n')
  DF <- data.frame(word=wordList, prob=as.numeric(probList), phono=phonoList, ortho=orthoList, op=OPList)
  return(list(first=DF, second=OPList))
}
TrfileNam <- 'TrEm_Harm1998_0.0.txt'; trf <- readLines(TrfileNam); head(trf, 20)
TefileNam <- 'Te_sqrt.txt'; tef <- readLines(TefileNam); head(tef, 20)

r <- crtDF(trf)
# noPh: 4017; noUniqueP: 3636; noOP: 4017 
DFtr <- r$first; OPList_tr <- r$second
write.csv(DFtr, './trainingexp.csv', row.names=FALSE)
r <- crtDF(tef)
# noPh: 48; noUniqueP: 48; noOP: 48 
DFte <- r$first; OPList_te <- r$second
write.csv(DFte, './testingexp.csv', row.names=FALSE)


##################################################
## get overall (average) performance data from a set of models. 
## Model outputs ("output.txt" files) are assumed to be in subdirectories relative to the current working directory.
readOutput <- function(f){
  print(f)
  prs <- str_split(f, "/", simplify=TRUE) # prs[1] is condition; prs[2] is run id; prs[3] is filename (output.txt)
  hlsize <- as.integer(str_extract(str_split(prs[1], "L", simplify=TRUE)[1], "[0-9]+"))
  lrnrate <- as.numeric(str_split(prs[1], "L", simplify=TRUE)[2])
  run <- as.integer(prs[2])
  retval <- read.delim(f)
  retval <- data.frame(hlsize, lrnrate, run, retval)
}
# get OtoP accuracy data
f <- dir(".", pattern="^output.txt$", recursive=TRUE)
avgaccu <- ldply(f, readOutput); names(avgaccu) <- str_to_lower(names(avgaccu))
write.csv(avgaccu, './AvgAcu_OtoP.csv', row.names=FALSE)
# draw OtoP training error
ggplot(avgaccu, aes(x=iter, y=err_o2p)) + scale_x_log10(labels=scinot) +  
  coord_cartesian(xlim=errrange_otop) + xlab("Training Trials (log10)") + ylab("Avg Err") +  
  ggtitle("Training Error x Trials (OtoP) \n Hid Layer & Learn Rate") +
  geom_point(alpha=.2, color="blue") + geom_smooth(span=.2, color="darkorange") + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'Error_OtoP.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')
# for runmode=3 or 4, draw PtoP training error
ggplot(avgaccu, aes(x=iter, y=err_p2p)) + scale_x_log10(labels=scinot) +  
  coord_cartesian(xlim=errrange_otop) + xlab("Training Trials (log10)") + ylab("Avg Err") +  
  ggtitle("Training Error x Trials (OtoP) \n Hid Layer & Learn Rate") +
  geom_point(alpha=.2, color="blue") + geom_smooth(span=.2, color="darkorange") + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'Error_PtoP_int.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')

# draw training accuracy
ggplot(avgaccu, aes(x=iter, y=acutr)) + scale_x_log10(labels=scinot) +  
  coord_cartesian(xlim=drawrange) + xlab("Training Trials (log10)") + ylab("Avg Acc") +  
  ggtitle("Training Acc x Trials \n Hid Layer & Learn Rate") +
  geom_point(alpha=.2, color="blue") + geom_smooth(span=.2, color="darkorange") + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'AvgAcc_Tr_OtoP.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')
# draw testing accuracy
ggplot(avgaccu, aes(x=iter, y=acute)) + scale_x_log10(labels=scinot) +  
  coord_cartesian(xlim=drawrange) + xlab("Training Trials (log10)") + ylab("Avg Acc") +  
  ggtitle("Testing Acc x Trials\n Hid Layer & Learn Rate") +
  geom_point(alpha=.2, color="blue") + geom_smooth(span=.2, color="darkorange") + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'AvgAcc_Te_OtoP.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')

# get PtoP accuracy data (only for runmode = 1 and 4)
f <- dir(".", pattern="^output_ptop.txt$", recursive=TRUE)
avgaccu_ptop <- ldply(f, readOutput); names(avgaccu_ptop) <- str_to_lower(names(avgaccu_ptop))
write.csv(avgaccu_ptop, './AvgAcu_PtoP.csv', row.names=FALSE)
# draw PtoP training error (only for runmode = 1 and 4)
ggplot(avgaccu_ptop, aes(x=iter, y=err)) + scale_x_log10(labels=scinot) +  
  coord_cartesian(xlim=errrange_ptop) + xlab("Training Trials (log10)") + ylab("Avg Err") +  
  ggtitle("Training Error x Trials (OtoP) \n Hid Layer & Learn Rate") +
  geom_point(alpha=.2, color="blue") + geom_smooth(span=.2, color="darkorange") + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'Error_PtoP.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')


##################################################
## calculate distribution of words in the OtoP traing example
f <- dir(".", pattern="^trainfreq.txt$", recursive=TRUE)
trainfreq <- ldply(f, readOutput); names(trainfreq) <- str_to_lower(names(trainfreq))
# draw distribution of occurrence of training examples
timepoint <- 1e6; runID <- 1
trainfreq_sub <- trainfreq[trainfreq$iter==timepoint & trainfreq$run==runID,]
# timepoint <- 1e6
# trainfreq_sub <- trainfreq[trainfreq$iter==timepoint,]
wrd <- which(str_detect(names(trainfreq_sub), "^f[0-9]+$")); names(wrd) <- 1:4017
freqdist <- tidyr::gather(trainfreq_sub, wrd, key="item", value="occur")

ggplot(freqdist, aes(x=item, y=occur, color=run)) + geom_bar(stat="identity", width=0.1, color=freqdist$run) +
  xlab("Training Examples") + ylab("Occurrence") +
  ggtitle(paste("Occurrence of Training Examples\nat ", timepoint, " training; Run ", runID, sep="")) +
  facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'FBar_OtoP_', timepoint, '.png', sep=""), dpi = 300, height = 6, width = 18, units = 'in')
ggplot(freqdist, aes(occur, color=run)) + geom_histogram(bins=50) + facet_grid(hlsize~lrnrate) +
  xlab("Occurrence") + ylab("Count") +
  ggtitle(paste("Histogram of Training Examples\n at ", timepoint, " Run ", runID, sep=""))
ggsave(paste(figDir, 'FHist_OtoP_', timepoint, '.png', sep=""), dpi = 300, height = 6, width = 18, units = 'in')
# log scale
ggplot(freqdist, aes(occur, color=run)) + geom_histogram(bins=50) + facet_grid(hlsize~lrnrate) +
  xlab("Occurrence") + ylab("Count") + scale_x_log10() +
  ggtitle(paste("Histogram of Training Examples\n at ", timepoint, " Run ", runID, sep=""))
ggsave(paste(figDir, 'FHist_OtoP_', timepoint, '_log.png', sep=""), dpi = 300, height = 6, width = 18, units = 'in')

# calculate distribution of words in the PtoP traing example
f <- dir(".", pattern="^trainfreq_ptop.txt$", recursive=TRUE)
trainfreq <- ldply(f, readOutput); names(trainfreq) <- str_to_lower(names(trainfreq))
# draw distribution of occurrence of training examples
timepoint <- 1e6; runID <- 1
trainfreq_sub <- trainfreq[trainfreq$iter==timepoint & trainfreq$run==runID,]
# timepoint <- 1e6
# trainfreq_sub <- trainfreq[trainfreq$iter==timepoint,]
wrd <- which(str_detect(names(trainfreq_sub), "^f[0-9]+$")); names(wrd) <- 1:4017
freqdist <- tidyr::gather(trainfreq_sub, wrd, key="item", value="occur")

ggplot(freqdist, aes(x=item, y=occur, color=run)) + geom_bar(stat="identity", width=0.1, color=freqdist$run) +
  xlab("Training Examples") + ylab("Occurrence") +
  ggtitle(paste("Occurrence of Training Examples\nat ", timepoint, " training; Run ", runID, sep="")) +
  facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'FBar_PtoP_', timepoint, '.png', sep=""), dpi = 300, height = 6, width = 18, units = 'in')
ggplot(freqdist, aes(occur, color=run)) + geom_histogram(bins=50) + facet_grid(hlsize~lrnrate) +
  xlab("Occurrence") + ylab("Count") +
  ggtitle(paste("Histogram of Training Examples\n at ", timepoint, " Run ", runID, sep=""))
ggsave(paste(figDir, 'FHist_PtoP_', timepoint, '.png', sep=""), dpi = 300, height = 6, width = 18, units = 'in')
# log scale
ggplot(freqdist, aes(occur, color=run)) + geom_histogram(bins=50) + facet_grid(hlsize~lrnrate) +
  xlab("Occurrence") + ylab("Count") + scale_x_log10() +
  ggtitle(paste("Histogram of Training Examples\n at ", timepoint, " Run ", runID, sep=""))
ggsave(paste(figDir, 'FHist_PtoP_', timepoint, '_log.png', sep=""), dpi = 300, height = 6, width = 18, units = 'in')


##################################################
## get word-level performance data from a set of models & tidy it. 
## Data files ("itemacu_tr.txt") are assumed to be in subdirectories 
## relative to the current working directory.
## "itemacu_tr.txt" for item accuracy. 
## "outphonTr.txt" for item activated phonological representations
## "outphonErrTr.txt" for item squared root errors
getItemAcuActPhonErr <- function(f1, f2, f3, OPList){
  ## read item accuracy data
  t <- ldply(f1, readOutput); names(t) <- str_to_lower(names(t))
  t <- t[-which(names(t) == "noitem")] # tidyr way to do this is ??
  ## re-label item columns, with wordforms (O.P) they represent
  wrd <- which(str_detect(names(t), "^acu[0-9]+$")) # find the right columns
  ## should probably double check to ensure length(wrd) == length(OP)
  names(t)[wrd] <- OPList # NB: wordforms (O-rep) are unique
  ## convert from wide to long format
  t <- tidyr::gather(t, wrd, key="OP", value="accuracy")
  t <- tidyr::separate(t, OP, into=c("O", "P"), sep="[.]")
  
  ## read activated phoneme data
  actphon <- ldply(f2, readOutput); names(actphon) <- str_to_lower(names(actphon))
  actphon <- actphon[-which(names(actphon) == "noitem")] # tidyr way to do this is ??
  ## re-label item columns, with wordforms (O.P) they represent
  actp_pos <- which(str_detect(names(actphon), "^phon[0-9]+$")) # find the right columns
  names(actphon)[actp_pos] <- OPList # NB: wordforms (O-rep) are unique
  ## convert from wide to long format
  tractp <- tidyr::gather(actphon, actp_pos, key="OP", value="actphon")
  tractp <- tidyr::separate(tractp, OP, into=c("O", "P"), sep="[.]")
  tractp$actphon <- gsub("_", "", tractp$actphon)
  # merge tr with tractp
  t$actphon <- tractp$actphon
  
  if(!is.null(f3)){
    ## read item squared root errors data
    err <- ldply(f3, readOutput); names(err) <- str_to_lower(names(err))
    err <- err[-which(names(err) == "noitem")] # tidyr way to do this is ??
    ## re-label item columns, with wordforms (O.P) they represent
    err_pos <- which(str_detect(names(err), "^err[0-9]+$")) # find the right columns
    names(err)[err_pos] <- OPList # NB: wordforms (O-rep) are unique
    ## convert from wide to long format
    trerr <- tidyr::gather(err, err_pos, key="OP", value="err")
    trerr <- tidyr::separate(trerr, OP, into=c("O", "P"), sep="[.]")
    trerr$err <- gsub("_", "", trerr$err)
    # merge tr with trerr
    t$err <- trerr$err
  }
  
  return(t)
}
# for OtoP training items
f1 <- dir(".", pattern="^itemacu_tr.txt$", recursive=TRUE)
f2 <- dir(".", pattern="^outphonTr.txt$", recursive=TRUE)
f3 <- dir(".", pattern="^outphonErrTr.txt$", recursive=TRUE)
tr <- getItemAcuActPhonErr(f1, f2, f3, OPList_tr)
write.csv(tr, './tr_allres_OtoP.csv', row.names=FALSE)
# for OtoP testing items
f1 <- dir(".", pattern="^itemacu_te.txt$", recursive=TRUE)
f2 <- dir(".", pattern="^outphonTe.txt$", recursive=TRUE)
f3 <- dir(".", pattern="^outphonErrTe.txt$", recursive=TRUE)
te <- getItemAcuActPhonErr(f1, f2, f3, OPList_te)
write.csv(te, './te_allres_OtoP.csv', row.names=FALSE)

# for PtoP training items
f1 <- dir(".", pattern="^itemacu_tr_ptop.txt$", recursive=TRUE)
f2 <- dir(".", pattern="^outphonTr_ptop.txt$", recursive=TRUE)
tr_ptop <- getItemAcuActPhonErr(f1, f2, NULL, OPList_tr)
write.csv(tr_ptop, './tr_allres_PtoP.csv', row.names=FALSE)
# for PtoP testing items
f1 <- dir(".", pattern="^itemacu_te_ptop.txt$", recursive=TRUE)
f2 <- dir(".", pattern="^outphonTe_ptop.txt$", recursive=TRUE)
te_ptop <- getItemAcuActPhonErr(f1, f2, NULL, OPList_te)
write.csv(te_ptop, './te_allres_PtoP.csv', row.names=FALSE)

## Plot average accuracy as output by model
tmp <- tr[,c("hlsize", "lrnrate", "iter", "avg")]; tmp <- unique(tmp)
ggplot(tmp, aes(x=iter, y=avg)) + scale_x_log10(labels=scinot) +
  coord_cartesian(xlim=drawrange) + xlab("Training Trials (log10)") + ylab("Avg Acc") +
  ggtitle("Training Acc x Trials\n Hid Layer & Learn Rate") +
  geom_point(alpha=.2, color="blue") + geom_smooth(span=.2, color="darkorange") + facet_grid(lrnrate~hlsize)
tmp <- te[,c("hlsize", "lrnrate", "iter", "avg")]; tmp <- unique(tmp)
ggplot(tmp, aes(x=iter, y=avg)) + scale_x_log10(labels=scinot) +
  coord_cartesian(xlim=drawrange) + xlab("Training Trials (log10)") + ylab("Avg Acc") +
  ggtitle("Testing Acc x Trials\n Hid Layer Size & Learn Rate") +
  geom_point(alpha=.2, color="blue") + geom_smooth(span=.2, color="darkorange") + facet_grid(lrnrate~hlsize)


##################################################
## Diffs based on phonological structure
getCVCdata <- function(type, t){
  consp <- c("p", "b", "t", "d", "k", "g", "f", "v", "T", "D", "s", "z", "h", "S", "B", "C", "J", "m", "n", "G", "r", "l", "w", "j")
  consp.re <- paste0("[", paste(consp, collapse=""), "]")
  vowo <- c("a", "e", "i", "o", "u")
  if(type=='Harm&Seidenberg1999'){ vowp <- c("i", "I", "E", "e", "@", "a", "x", "o", "U", "u", "^"); vowp.re <- paste0("[", paste(vowp, collapse="|"), "]")
  }else if(type=='Harm1998'){ vowp <- c("i", "I", "E", "e", "@", "a", "o", "U", "u", "^", "W", "Y", "A", "O"); vowp.re <- paste0("[", paste(vowp, collapse=""), "]")
  }
  cvc.re <- paste0("^", consp.re, "{1}", vowp.re, "{1}", consp.re, "{1}", "$")
  ccvc.re <- paste0("^", consp.re, "{2}", vowp.re, "{1}", consp.re, "{1}", "$")
  cvcc.re <- paste0("^", consp.re, "{1}", vowp.re, "{1}", consp.re, "{2}", "$")
  ccvcc.re <- paste0("^", consp.re, "{2}", vowp.re, "{1}", consp.re, "{2}", "$")
  
  Pcvc <- str_detect(t$P, cvc.re); Pccvc <- str_detect(t$P, ccvc.re)
  Pcvcc <- str_detect(t$P, cvcc.re); Pccvcc <- str_detect(t$P, ccvcc.re)
  syl <- rep(NA, length.out=length(Pcvc))
  syl[Pcvc] <- "cvc"; syl[Pccvc] <- "ccvc"; syl[Pcvcc] <- "cvcc"; syl[Pccvcc] <- "ccvcc"
  
  ts <- data.frame(t, syl); tsub <- subset(ts, !is.na(syl))
  cat('noCVC: ', length(unique(tsub$O[tsub$syl=="cvc"])), '; noCVCC: ', length(unique(tsub$O[tsub$syl=="cvcc"])), 
      '; noCCVC: ', length(unique(tsub$O[tsub$syl=="ccvc"])), '; noCCVCC: ', length(unique(tsub$O[tsub$syl=="ccvcc"])), '\n')
  return(tsub)
}
## Based on Harm & Seidenberg 1999
# trsub <- getCVCdata("Harm&Seidenberg1999", tr)
# tesub <- getCVCdata("Harm&Seidenberg1999", te)
## Based on Harm 1998
trsub <- getCVCdata("Harm1998", tr) # noCVC:  1515 ; noCVCC:  814 ; noCCVC:  785 ; noCCVCC:  284
tesub <- getCVCdata("Harm1998", te) # noCVC:  48 ; noCVCC:  0 ; noCCVC:  0 ; noCCVCC:  0 

## find phon forms that are CVC with simple vowels. This def will also include CV, where V is a diphthong (e.g., pay, buy).
ggplot(trsub, aes(x=iter, y=accuracy)) + scale_x_log10(labels=scinot) +
  coord_cartesian(xlim=drawrange) + xlab("Training Trials (log10)") + ylab("Avg Acc") +
  ggtitle("Training Phon CVC vs. CCVC vs. CVCC vs. CCVCC") +
  geom_smooth(aes(color=as.factor(syl)), span=.2) + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'CVCAcc_tr.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')
ggplot(tesub, aes(x=iter, y=accuracy)) + scale_x_log10(labels=scinot) +
  coord_cartesian(xlim=drawrange) + xlab("Training Trials (log10)") + ylab("Avg Acc") +
  ggtitle("Testing Phon CVC vs. CCVC vs. CVCC vs. CCVCC") +
  geom_smooth(aes(color=as.factor(syl)), span=.2) + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'CVCAcc_te.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')


# ##### split items randomly into 4 groups
# doGroups <- function(d){
#   group <- sample(LETTERS[1:4], 1)
#   data.frame(d, group)
# }
# trsr <- ddply(trsub, "O", doGroups) ## will create a different random
# ## grouping each time this is run
# windows()
# ggplot(trsr, aes(x=iter, y=accuracy)) + scale_x_log10(labels=scinot) +
#   coord_cartesian(xlim=drawrange) + xlab("Training Trials (log10)") + ylab("Avg Acc") +
#   geom_smooth(aes(color=group), span=.2) + 
#   ggtitle("Randomly Grouped") + facet_grid(lrnrate~hlsize)
# ## compare a few of these to calibrate the eye
# 
# doGroupsN <- function(run, df){
#   data.frame(run, ddply(df, "O", doGroups))
# }
# runs <- 1:4
# trsr4 <- ldply(runs, doGroupsN, trsub)
# windows()
# ggplot(trsr4, aes(x=iter, y=accuracy)) + scale_x_log10(labels=scinot) +
#   coord_cartesian(xlim=drawrange) + xlab("Training Trials (log10)") + ylab("Avg Acc") +
#   geom_smooth(aes(color=group), span=.2) + 
#   facet_wrap(~run, nrow=2) + ggtitle("Randomly Grouped, 4 ways") + facet_grid(lrnrate~hlsize)
# ##### break out sensible word groups to look at performance in more
# ##### detail
# 
# ## length based categories
# Olen <- str_length(tr$O) ## letter length
# Plen <- str_length(tr$P) ## phoneme length
# trsa <- data.frame(tr, Olen, Plen)
# trsa <- data.frame(trsa, matchlen=Olen==Plen)
# 
# ggplot(trsa, aes(x=iter, y=accuracy)) + scale_x_log10(labels=scinot) +
#   coord_cartesian(xlim=drawrange) + geom_smooth(aes(color=matchlen), span=.2) +
#   ggtitle("O length == P length vs. O length != P length") + facet_grid(lrnrate~hlsize)
#  
# trsa2 <- data.frame(trsa, difflen=Olen-Plen)
# ggplot(trsa2, aes(x=iter, y=accuracy)) + scale_x_log10(labels=scinot) +
#   coord_cartesian(xlim=drawrange) + geom_smooth(aes(color=as.factor(difflen)), span=.2) +
#   ggtitle("O length minus P length") + facet_grid(lrnrate~hlsize)
# ggsave('Acu_OminusP.png', dpi = 300, height = 6, width = 12, units = 'in')
# 
# ## Words with fewer letters than phonemes are the easiest cases to
# ## learn (e.g., ax, fix, next, fry, sky). Words that match in O and P ength are the next easiest, and those with 1 fewer phones than
# ## letters are next. Some bins are small; see the confidence intervals.
# 
# ggplot(trsa2, aes(x=iter, y=accuracy)) + scale_x_log10(labels=scinot) +
#   coord_cartesian(xlim=drawrange) + geom_smooth(aes(color=as.factor(Plen)), span=.2) +
#   ggtitle("Length in Phonemes") + facet_grid(lrnrate~hlsize)
# ggsave('PlengAcu.png', dpi = 300, height = 6, width = 12, units = 'in')
# ## Relationship between word length (in phonemes) and accuracy. 
# ## Shorter words are learned less well. That's just plain weird.
# 
# ## Words with C that are often written as digraphs (e.g., ship, chip, judge, the, this) vs. those without such C.
# digr.re <- "[TSDCG]"
# Pdigr <- str_detect(trsa2$P, digr.re)
# trsa2 <- data.frame(trsa2, Pdigr)
# 
# ggplot(trsa2, aes(x=iter, y=accuracy)) + scale_x_log10(labels=scinot) +
#   coord_cartesian(xlim=drawrange) + geom_smooth(aes(color=as.factor(Pdigr)), span=.2) +
#   ggtitle("Probable Digraph C vs. Other") + facet_grid(lrnrate~hlsize)
# ## Digraphs are harder to learn. Not surprising.


# # get words' frequencies
# mean_log_freq <- mean(DFtr$prob) # 0.2017773
# DFtr$mean[DFtr$prob>=mean_log_freq] <- "H"; DFtr$mean[DFtr$prob<mean_log_freq] <- "L"
# DFmerge <- DFtr[,c("word", "prob", "mean")]; names(DFmerge) <- c("O", "log_freq", "freq_mean")
# tr2 <- merge(tr, DFmerge, by = c("O"), all.x = TRUE, all.y = TRUE)
# write.csv(tr2, "AllRes_tr.csv", row.names=FALSE)
# 
# mean_log_freq <- mean(DFte$prob) # 0.05
# DFte$mean[DFte$prob>=mean_log_freq] <- "H"; DFte$mean[DFte$prob<mean_log_freq] <- "L"
# DFmerge <- DFte[,c("word", "prob", "mean")]; names(DFmerge) <- c("O", "log_freq", "freq_mean")
# te2 <- merge(te, DFmerge, by = c("O"), all.x = TRUE, all.y = TRUE)
# write.csv(te2, "AllRes_te.csv", row.names=FALSE)