library(stringr)
library(reshape2)
library(tidyr)
library(ggplot2)
library(hexbin)
library(plyr)
library(Rmisc)

options(max.print=10000)
drawrange <- c(1e4,1e8); errrange_ptos <- c(10, 1e8); errrange_stos <- c(10, 1e8)
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
  semList <- getList(t, "Rep_S: (['_/a-zA-Z]+)", "Rep_S: ") # get semantic representations
  P <- str_replace_all(phonoList, "(_|/)", "")
  PSList <- paste(P, semList, sep=".") # create PS list
  cat('noSem: ', length(unique(semList)), '; noUniqueP: ', length(unique(P)),'; noPS: ', length(unique(PSList)), '\n')
  DF <- data.frame(word=wordList, prob=as.numeric(probList), phono=phonoList, sem=semList, ps=PSList)
  return(list(first=DF, second=PSList))
}
TrfileNam <- 'Tr_nohomo_300_PtoS_0.0.txt'; trf <- readLines(TrfileNam); head(trf, 20)
TefileNam <- 'Tr_nohomo_300_PtoS_0.0.txt'; tef <- readLines(TefileNam); head(tef, 20)

r <- crtDF(trf)
# noPh: 3627; noUniqueP: 3627; noOP: 3627 
DFtr <- r$first; PSList_tr <- r$second
write.csv(DFtr, './trainingexp.csv', row.names=FALSE)
r <- crtDF(tef)
# noPh: 3627; noUniqueP: 3627; noOP: 3627 
DFte <- r$first; PSList_te <- r$second
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
# get PtoS accuracy data
f <- dir(".", pattern="^output.txt$", recursive=TRUE)
avgaccu <- ldply(f, readOutput); names(avgaccu) <- str_to_lower(names(avgaccu))
write.csv(avgaccu, './AvgAcu_PtoS.csv', row.names=FALSE)
# draw PtoS training error
ggplot(avgaccu, aes(x=iter, y=err_o2s)) + scale_x_log10(labels=scinot) +  
  coord_cartesian(xlim=errrange_ptos) + xlab("Training Trials (log10)") + ylab("Avg Err") +  
  ggtitle("Training Error x Trials (PtoS) \n Hid Layer & Learn Rate") +
  geom_point(alpha=.2, color="blue") + geom_smooth(span=.2, color="darkorange") + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'Error_PtoS.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')
# for runmode=3 or 4, draw StoS training error
ggplot(avgaccu, aes(x=iter, y=err_s2s)) + scale_x_log10(labels=scinot) +  
  coord_cartesian(xlim=errrange_stos) + xlab("Training Trials (log10)") + ylab("Avg Err") +  
  ggtitle("Training Error x Trials (StoS) \n Hid Layer & Learn Rate") +
  geom_point(alpha=.2, color="blue") + geom_smooth(span=.2, color="darkorange") + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'Error_StoS_int.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')

# draw training accuracy
ggplot(avgaccu, aes(x=iter, y=acutr)) + scale_x_log10(labels=scinot) +  
  coord_cartesian(xlim=drawrange, ylim=c(0.0,1.0)) + xlab("Training Trials (log10)") + ylab("Avg Acc") +  
  ggtitle("Training Acc x Trials \n Hid Layer & Learn Rate") +
  geom_point(alpha=.2, color="blue") + geom_smooth(span=.2, color="darkorange") + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'AvgAcc_Tr_PtoS.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')
# draw testing accuracy
ggplot(avgaccu, aes(x=iter, y=acute)) + scale_x_log10(labels=scinot) +  
  coord_cartesian(xlim=drawrange, ylim=c(0.0,1.0)) + xlab("Training Trials (log10)") + ylab("Avg Acc") +  
  ggtitle("Testing Acc x Trials\n Hid Layer & Learn Rate") +
  geom_point(alpha=.2, color="blue") + geom_smooth(span=.2, color="darkorange") + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'AvgAcc_Te_PtoS.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')

# get StoS accuracy data (only for runmode = 1 and 4)
f <- dir(".", pattern="^output_stos.txt$", recursive=TRUE)
avgaccu_stos <- ldply(f, readOutput); names(avgaccu_stos) <- str_to_lower(names(avgaccu_stos))
write.csv(avgaccu_stos, './AvgAcu_StoS.csv', row.names=FALSE)
# draw StoS training error (only for runmode = 1 and 4)
ggplot(avgaccu_stos, aes(x=iter, y=err)) + scale_x_log10(labels=scinot) +  
  coord_cartesian(xlim=errrange_stos) + xlab("Training Trials (log10)") + ylab("Avg Err") +  
  ggtitle("Training Error x Trials (StoS) \n Hid Layer & Learn Rate") +
  geom_point(alpha=.2, color="blue") + geom_smooth(span=.2, color="darkorange") + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'Error_StoS.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')


##################################################
## calculate distribution of words in the PtoS traing example
f <- dir(".", pattern="^trainfreq.txt$", recursive=TRUE)
trainfreq <- ldply(f, readOutput); names(trainfreq) <- str_to_lower(names(trainfreq))
# draw distribution of occurrence of training examples
timepoint <- 1e6; runID <- 1
trainfreq_sub <- trainfreq[trainfreq$iter==timepoint & trainfreq$run==runID,]
# timepoint <- 1e6
# trainfreq_sub <- trainfreq[trainfreq$iter==timepoint,]
wrd <- which(str_detect(names(trainfreq_sub), "^f[0-9]+$")); names(wrd) <- 1:3627
freqdist <- tidyr::gather(trainfreq_sub, wrd, key="item", value="occur")

ggplot(freqdist, aes(x=item, y=occur, color=run)) + geom_bar(stat="identity", width=0.1, color=freqdist$run) +
  xlab("Training Examples") + ylab("Occurrence") +
  ggtitle(paste("Occurrence of Training Examples\nat ", timepoint, " training; Run ", runID, sep="")) +
  facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'FBar_PtoS_', timepoint, '.png', sep=""), dpi = 300, height = 6, width = 18, units = 'in')
ggplot(freqdist, aes(occur, color=run)) + geom_histogram(bins=50) + facet_grid(hlsize~lrnrate) +
  xlab("Occurrence") + ylab("Count") +
  ggtitle(paste("Histogram of Training Examples\n at ", timepoint, " Run ", runID, sep=""))
ggsave(paste(figDir, 'FHist_PtoS_', timepoint, '.png', sep=""), dpi = 300, height = 6, width = 18, units = 'in')
# log scale
ggplot(freqdist, aes(occur, color=run)) + geom_histogram(bins=50) + facet_grid(hlsize~lrnrate) +
  xlab("Occurrence") + ylab("Count") + scale_x_log10() +
  ggtitle(paste("Histogram of Training Examples\n at ", timepoint, " Run ", runID, sep=""))
ggsave(paste(figDir, 'FHist_PtoS_', timepoint, '_log.png', sep=""), dpi = 300, height = 6, width = 18, units = 'in')

# calculate distribution of words in the StoS traing example
f <- dir(".", pattern="^trainfreq_stos.txt$", recursive=TRUE)
trainfreq <- ldply(f, readOutput); names(trainfreq) <- str_to_lower(names(trainfreq))
# draw distribution of occurrence of training examples
timepoint <- 1e6; runID <- 1
trainfreq_sub <- trainfreq[trainfreq$iter==timepoint & trainfreq$run==runID,]
# timepoint <- 1e6
# trainfreq_sub <- trainfreq[trainfreq$iter==timepoint,]
wrd <- which(str_detect(names(trainfreq_sub), "^f[0-9]+$")); names(wrd) <- 1:3627
freqdist <- tidyr::gather(trainfreq_sub, wrd, key="item", value="occur")

ggplot(freqdist, aes(x=item, y=occur, color=run)) + geom_bar(stat="identity", width=0.1, color=freqdist$run) +
  xlab("Training Examples") + ylab("Occurrence") +
  ggtitle(paste("Occurrence of Training Examples\nat ", timepoint, " training; Run ", runID, sep="")) +
  facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'FBar_StoS_', timepoint, '.png', sep=""), dpi = 300, height = 6, width = 18, units = 'in')
ggplot(freqdist, aes(occur, color=run)) + geom_histogram(bins=50) + facet_grid(hlsize~lrnrate) +
  xlab("Occurrence") + ylab("Count") +
  ggtitle(paste("Histogram of Training Examples\n at ", timepoint, " Run ", runID, sep=""))
ggsave(paste(figDir, 'FHist_StoS_', timepoint, '.png', sep=""), dpi = 300, height = 6, width = 18, units = 'in')
# log scale
ggplot(freqdist, aes(occur, color=run)) + geom_histogram(bins=50) + facet_grid(hlsize~lrnrate) +
  xlab("Occurrence") + ylab("Count") + scale_x_log10() +
  ggtitle(paste("Histogram of Training Examples\n at ", timepoint, " Run ", runID, sep=""))
ggsave(paste(figDir, 'FHist_StoS_', timepoint, '_log.png', sep=""), dpi = 300, height = 6, width = 18, units = 'in')


##################################################
## get word-level performance data from a set of models & tidy it. 
## Data files ("itemacu_tr.txt") are assumed to be in subdirectories 
## relative to the current working directory.
## "itemacu_tr.txt" for item accuracy. 
## "outsemTr.txt" for item activated semantic representations
## "outsemErrTr.txt" for item squared root errors
getItemAcuActSemErr <- function(f1, f2, f3, PSList){
  ## read item accuracy data
  t <- ldply(f1, readOutput); names(t) <- str_to_lower(names(t))
  t <- t[-which(names(t) == "noitem")] # tidyr way to do this is ??
  ## re-label item columns, with wordforms (P.S) they represent
  wrd <- which(str_detect(names(t), "^acu[0-9]+$")) # find the right columns
  ## should probably double check to ensure length(wrd) == length(PS)
  names(t)[wrd] <- PSList # NB: wordforms (S-rep) are unique
  ## convert from wide to long format
  t <- tidyr::gather(t, wrd, key="PS", value="accuracy")
  t <- tidyr::separate(t, PS, into=c("P", "S"), sep="[.]")
  
  ## read activated semantic data
  actsem <- ldply(f2, readOutput); names(actsem) <- str_to_lower(names(actsem))
  actsem <- actsem[-which(names(actsem) == "noitem")] # tidyr way to do this is ??
  ## re-label item columns, with wordforms (P.S) they represent
  acts_pos <- which(str_detect(names(actsem), "^sem[0-9]+$")) # find the right columns
  names(actsem)[acts_pos] <- PSList # NB: wordforms (S-rep) are unique
  ## convert from wide to long format
  tracts <- tidyr::gather(actsem, acts_pos, key="PS", value="actsem")
  tracts <- tidyr::separate(tracts, PS, into=c("P", "S"), sep="[.]")
  tracts$actsem <- gsub("_", "", tracts$actsem)
  # merge tr with tracts
  t$actsem <- tracts$actsem
  
  if(!is.null(f3)){
    ## read item squared root errors data
    err <- ldply(f3, readOutput); names(err) <- str_to_lower(names(err))
    err <- err[-which(names(err) == "noitem")] # tidyr way to do this is ??
    ## re-label item columns, with wordforms (P.S) they represent
    err_pos <- which(str_detect(names(err), "^err[0-9]+$")) # find the right columns
    names(err)[err_pos] <- PSList # NB: wordforms (S-rep) are unique
    ## convert from wide to long format
    trerr <- tidyr::gather(err, err_pos, key="PS", value="err")
    trerr <- tidyr::separate(trerr, PS, into=c("P", "S"), sep="[.]")
    trerr$err <- gsub("_", "", trerr$err)
    # merge tr with trerr
    t$err <- trerr$err
  }
  
  return(t)
}
# for PtoS training items
f1 <- dir(".", pattern="^itemacu_tr.txt$", recursive=TRUE)
f2 <- dir(".", pattern="^outsemTr.txt$", recursive=TRUE)
f3 <- dir(".", pattern="^outsemErrTr.txt$", recursive=TRUE)
tr <- getItemAcuActSemErr(f1, f2, f3, PSList_tr)
write.csv(tr, './tr_allres_PtoS.csv', row.names=FALSE)
# for PtoS testing items
f1 <- dir(".", pattern="^itemacu_te.txt$", recursive=TRUE)
f2 <- dir(".", pattern="^outsemTe.txt$", recursive=TRUE)
f3 <- dir(".", pattern="^outsemErrTe.txt$", recursive=TRUE)
te <- getItemAcuActSemErr(f1, f2, f3, PSList_te)
write.csv(te, './te_allres_PtoS.csv', row.names=FALSE)

# for StoS training items
f1 <- dir(".", pattern="^itemacu_tr_stos.txt$", recursive=TRUE)
f2 <- dir(".", pattern="^outsemTr_stos.txt$", recursive=TRUE)
tr_stos <- getItemAcuActSemErr(f1, f2, NULL, PSList_tr)
write.csv(tr_stos, './tr_allres_StoS.csv', row.names=FALSE)
# for StoS testing items
f1 <- dir(".", pattern="^itemacu_te_stos.txt$", recursive=TRUE)
f2 <- dir(".", pattern="^outsemTe_stos.txt$", recursive=TRUE)
te_stos <- getItemAcuActSemErr(f1, f2, NULL, OPList_te)
write.csv(te_stos, './te_allres_StoS.csv', row.names=FALSE)

## Plot average accuracy as output by model
tmp <- tr[,c("hlsize", "lrnrate", "iter", "avg")]; tmp <- unique(tmp)
ggplot(tmp, aes(x=iter, y=avg)) + scale_x_log10(labels=scinot) +
  coord_cartesian(xlim=drawrange, ylim=c(0.0,1.0)) + xlab("Training Trials (log10)") + ylab("Avg Acc") +
  ggtitle("Training Acc x Trials\n Hid Layer & Learn Rate") +
  geom_point(alpha=.2, color="blue") + geom_smooth(span=.2, color="darkorange") + facet_grid(lrnrate~hlsize)
tmp <- te[,c("hlsize", "lrnrate", "iter", "avg")]; tmp <- unique(tmp)
ggplot(tmp, aes(x=iter, y=avg)) + scale_x_log10(labels=scinot) +
  coord_cartesian(xlim=drawrange, ylim=c(0.0,1.0)) + xlab("Training Trials (log10)") + ylab("Avg Acc") +
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
  cat('noCVC: ', length(unique(tsub$S[tsub$syl=="cvc"])), '; noCVCC: ', length(unique(tsub$S[tsub$syl=="cvcc"])), 
      '; noCCVC: ', length(unique(tsub$S[tsub$syl=="ccvc"])), '; noCCVCC: ', length(unique(tsub$S[tsub$syl=="ccvcc"])), '\n')
  return(tsub)
}
## Based on Harm & Seidenberg 1999
# trsub <- getCVCdata("Harm&Seidenberg1999", tr)
# tesub <- getCVCdata("Harm&Seidenberg1999", te)
## Based on Harm 1998
# calculate meanings based on different phonological structures
trsub <- getCVCdata("Harm1998", tr) # noCVC:  1311 ; noCVCC:  769 ; noCCVC:  744 ; noCCVCC:  278
tesub <- getCVCdata("Harm1998", te) # noCVC:  1311 ; noCVCC:  769 ; noCCVC:  744 ; noCCVCC:  278 

## find phon forms that are CVC with simple vowels. This def will also include CV, where V is a diphthong (e.g., pay, buy).
ggplot(trsub, aes(x=iter, y=accuracy)) + scale_x_log10(labels=scinot) +
  coord_cartesian(xlim=drawrange, ylim=c(0.0,1.0)) + xlab("Training Trials (log10)") + ylab("Avg Acc") +
  ggtitle("Training Phon CVC vs. CCVC vs. CVCC vs. CCVCC") +
  geom_smooth(aes(color=as.factor(syl)), span=.2) + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'CVCAcc_tr.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')
ggplot(tesub, aes(x=iter, y=accuracy)) + scale_x_log10(labels=scinot) +
  coord_cartesian(xlim=drawrange, ylim=c(0.0,1.0)) + xlab("Training Trials (log10)") + ylab("Avg Acc") +
  ggtitle("Testing Phon CVC vs. CCVC vs. CVCC vs. CCVCC") +
  geom_smooth(aes(color=as.factor(syl)), span=.2) + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'CVCAcc_te.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')


# ##### split items randomly into 4 groups
# doGroups <- function(d){
#   group <- sample(LETTERS[1:4], 1)
#   data.frame(d, group)
# }
# trsr <- ddply(trsub, "S", doGroups) ## will create a different random
# ## grouping each time this is run
# windows()
# ggplot(trsr, aes(x=iter, y=accuracy)) + scale_x_log10(labels=scinot) +
#   coord_cartesian(xlim=drawrange) + xlab("Training Trials (log10)") + ylab("Avg Acc") +
#   geom_smooth(aes(color=group), span=.2) + 
#   ggtitle("Randomly Grouped") + facet_grid(lrnrate~hlsize)
# ## compare a few of these to calibrate the eye
# 
# doGroupsN <- function(run, df){
#   data.frame(run, ddply(df, "S", doGroups))
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