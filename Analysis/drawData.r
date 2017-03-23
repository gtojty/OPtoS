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

pd <- position_dodge(0.1)
drawpoints <- c(1e6, 3e6, 5e6, 7e6, 9e6, 1e7)

# calculate and store aov results;
aovSub <- function(hlsize, lrnrate, drawpoint, data, txtName, aovtype){
  # get subdata
  subdata <- subset(data, hlsize == hlsize & lrnrate==lrnrate & iter==drawpoint)
  # anova test
  if(aovtype=="freq*reg"){ aovfit <- aov(err ~ freq*reg, data=subdata)
  }else{ 
    if(aovtype=="freq*const"){ aovfit <- aov(err ~ freq*const, data=subdata)
    }
  }
  s <- summary(aovfit); capture.output(s, file=paste(figDir, txtName, sep=""))
}

# calculate and draw figures
drawSub <- function(hlsize, lrnrate, drawpoint, data, picName, limits, title, aovtype){
  # get subdata
  subdata <- subset(data, hlsize == hlsize & lrnrate==lrnrate & iter==drawpoint)
  # anova test
  if(aovtype=="freq*reg"){ 
    subdata_SE <- summarySE(subdata, measurevar="err", groupvars=c("freq", "reg", "hlsize", "lrnrate"), na.rm=TRUE)
    # draw figure
    ggplot(subdata_SE, aes(x=freq, y=err, linetype=reg, group=reg)) + 
      geom_errorbar(aes(ymin=err-se, ymax=err+se), size=1.5, width=.1, position=pd) +
      geom_line(position=pd, size=1.5) + geom_point(position=pd) + scale_y_continuous(limits=limits) + 
      xlab("Frequency") + ylab("SSE") + ggtitle(paste("F x R: ", title, "\n Hid Layer & Learn Rate at ", drawpoint, sep="")) +
      facet_grid(lrnrate~hlsize)
  }else{ 
    if(aovtype=="freq*const"){ 
      subdata_SE <- summarySE(subdata, measurevar="err", groupvars=c("freq", "const", "hlsize", "lrnrate"), na.rm=TRUE)
      # draw figure
      ggplot(subdata_SE, aes(x=freq, y=err, linetype=const, group=const)) + 
        geom_errorbar(aes(ymin=err-se, ymax=err+se), size=1.5, width=.1, position=pd) +
        geom_line(position=pd, size=1.5) + geom_point(position=pd) + scale_y_continuous(limits=limits) + 
        xlab("Frequency") + ylab("SSE") + ggtitle(paste("F x C: ", title, "\n Hid Layer & Learn Rate at ", drawpoint, sep="")) +
        facet_grid(lrnrate~hlsize)
    }
  }
  ggsave(paste(figDir, picName, sep=""), dpi = 300, height = 6, width = 12, units = 'in')
}


##################################################
## read data from csv files
DFtr <- read.csv('./trainingexp.csv'); DFtr_merge <- DFtr[,c('word', 'prob')]; names(DFtr_merge) <- c("S", "log_freq")
DFte <- read.csv('./testingexp.csv'); DFte_merge <- DFte[,c('word', 'prob')]; names(DFte_merge) <- c("S", "log_freq")
tr <- read.csv('./tr_allres_PtoS.csv'); tr$S <- gsub("'", "", tr$S)
te <- read.csv('./te_allres_PtoS.csv'); te$S <- gsub("'", "", te$S)

# Strain et al. 1995A:
Str1995A <- read.csv("Strain-etal-1995-Appendix-A.csv")
trStr1995A <- subset(tr, tr$S %in% Str1995A$S); trStr1995A <- merge(trStr1995A, Str1995A, by = c("S"), all.x = TRUE, all.y = FALSE)
frStr1995A <- subset(trStr1995A, freq == "H" | freq == "L")
cat(length(unique(frStr1995A$S)), '\n')
# 56
# save frStr1995A
write.csv(frStr1995A, "Str1995A.csv", row.names=FALSE)

# draw accuracy
ggplot(frStr1995A, aes(x=iter, y=accuracy, color=interaction(freq, reg))) + scale_x_log10(labels=scinot) + coord_cartesian(xlim=drawrange) + 
  scale_y_continuous(limits=c(0.0, 1.0)) +
  xlab("Training Trials (log10)") + ylab("Avg Acc") + ggtitle("Acc x Trials: Strain etal 1995 \n Hid Layer & Learn Rate") +
  geom_smooth(span=.2, aes(color=interaction(freq, reg))) + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'Str1995A_acu.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')
# draw sum squared error
errRange <- c(0.0, 200.0)
ggplot(frStr1995A, aes(x=iter, y=err, color=interaction(freq, reg))) + scale_x_log10(labels=scinot) + coord_cartesian(xlim=drawrange) + 
  scale_y_continuous(limits=errRange) +
  xlab("Training Trials (log10)") + ylab("Avg Err") + ggtitle("Err x Trials: Strain etal 1995 \n Hid Layer & Learn Rate") +
  geom_smooth(span=.2, aes(color=interaction(freq, reg))) + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'Str1995A_sse.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')

# anova test (for results under a single setting!)
aovfit <- aov(err ~ freq*reg + hlsize*lrnrate, data=frStr1995A)
s <- summary(aovfit); capture.output(s, file=paste(figDir, 'Str1995A_sseavg', '.txt', sep=""))
frStr1995A_avg <- summarySE(frStr1995A, measurevar="err", groupvars=c("freq", "reg", "hlsize", "lrnrate"), na.rm=TRUE)
errRange <- c(0.0, 200.0)
ggplot(frStr1995A_avg, aes(x=freq, y=err, linetype=reg, group=reg)) + 
  geom_errorbar(aes(ymin=err-se, ymax=err+se), size=1.5, width=.1, position=pd) +
  geom_line(position=pd, size=1.5) + geom_point(position=pd) + scale_y_continuous(limits=errRange) + 
  xlab("Frequency") + ylab("SSE") + ggtitle("F x R: Strain etal 1995 \n Hid Layer & Learn Rate") +
  facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'Str1995A_sseavg.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')

# drawpoints
hlsize <- 100; lrnrate <- 5e-2
# get subdata across all drawpoints
frStr1995A_cross <- subset(frStr1995A, iter %in% drawpoints)
frStr1995A_cross <- frStr1995A_cross[frStr1995A_cross$hlsize==hlsize & frStr1995A_cross$lrnrate==lrnrate, ]
# anova test
aovfit2 <- aov(err ~ freq*reg + iter, data=frStr1995A_cross)
s <- summary(aovfit2); capture.output(s, file=paste(figDir, 'Str1995A_sseavg_cross', '.txt', sep=""))
frStr1995A_cross_avg <- summarySE(frStr1995A_cross, measurevar="err", groupvars=c("freq", "reg", "hlsize", "lrnrate", "iter"), na.rm=TRUE)
errRange <- c(0.0, 200.0)
ggplot(frStr1995A_cross_avg, aes(x=freq, y=err, linetype=reg, group=reg)) + 
  geom_errorbar(aes(ymin=err-se, ymax=err+se), size=1.5, width=.1, position=pd) +
  geom_line(position=pd, size=1.5) + geom_point(position=pd) + scale_y_continuous(limits=errRange) + 
  xlab("Frequency") + ylab("SSE") + ggtitle("F x R: Strain etal 1995 \n Hid Layer & Learn Rate") +
  facet_wrap(~iter, nrow=2)
ggsave(paste(figDir, 'Str1995A_sseavg_cross.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')

# draw each point
for(drawpoint in drawpoints){
  txtName <- paste('Str1995A_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoint, '.txt', sep="")
  aovSub(hlsize, lrnrate, drawpoint, frStr1995A, txtName, "freq*reg")
}
picName <- paste('Str1995A_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[1], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[1], frStr1995A, picName, c(0.0, 7.0), 'Strain etal 1995A', "freq*reg")
picName <- paste('Str1995A_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[2], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[2], frStr1995A, picName, c(0.0, 5.0), 'Strain etal 1995A', "freq*reg")
picName <- paste('Str1995A_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[3], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[3], frStr1995A, picName, c(0.0, 4.0), 'Strain etal 1995A', "freq*reg")
picName <- paste('Str1995A_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[4], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[4], frStr1995A, picName, c(0.0, 3.0), 'Strain etal 1995A', "freq*reg")
picName <- paste('Str1995A_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[5], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[5], frStr1995A, picName, c(0.0, 3.0), 'Strain etal 1995A', "freq*reg")
picName <- paste('Str1995A_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[6], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[6], frStr1995A, picName, c(0.0, 2.0), 'Strain etal 1995A', "freq*reg")


# Taraban & McClelland 1987A1:
TM1987A1 <- read.csv("Taraban-McClelland-1987-Appendix-A1.csv", na.strings='na')
trTM1987A1 <- subset(tr, tr$S %in% TM1987A1$S); trTM1987A1 <- merge(trTM1987A1, TM1987A1, by = c("S"), all.x = TRUE, all.y = FALSE)
frTM1987A1 <- subset(trTM1987A1, freq == "H" | freq == "L")
cat(length(unique(frTM1987A1$O)), '\n')
# 94
# save frTM1987A1
write.csv(frTM1987A1, "TM1987A1.csv", row.names=FALSE)

# draw accuracy
ggplot(frTM1987A1, aes(x=iter, y=accuracy, color=interaction(freq, reg))) + scale_x_log10(labels=scinot) + coord_cartesian(xlim=drawrange) + 
  scale_y_continuous(limits=c(0.0, 1.0)) +
  xlab("Training Trials (log10)") + ylab("Avg Acc") + ggtitle("Acc x Trials: Taraban & McClelland 1987 A1\n Hid Layer & Learn Rate") +
  geom_smooth(span=.2, aes(color=interaction(freq, reg))) + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'TM1987A1_acu.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')
# draw sum squared error
errRange <- c(0.0, 200.0)
ggplot(frTM1987A1, aes(x=iter, y=err, color=interaction(freq, reg))) + scale_x_log10(labels=scinot) + coord_cartesian(xlim=drawrange) + 
  scale_y_continuous(limits=errRange) +
  xlab("Training Trials (log10)") + ylab("Avg Err") + ggtitle("Err x Trials: Taraban & McClelland 1987 A1\n Hid Layer & Learn Rate") +
  geom_smooth(span=.2, aes(color=interaction(freq, reg))) + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'TM1987A1_sse.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')

# anova test (for results under a single setting!)
aovfit <- aov(err ~ freq*reg + hlsize*lrnrate, data=frTM1987A1)
s <- summary(aovfit); capture.output(s, file=paste(figDir, 'TM1987A1_sseavg', '.txt', sep=""))
frTM1987A1_avg <- summarySE(frTM1987A1, measurevar="err", groupvars=c("freq", "reg", "hlsize", "lrnrate"), na.rm=TRUE)
errRange <- c(0.0, 200.0)
ggplot(frTM1987A1_avg, aes(x=freq, y=err, linetype=reg, group=reg)) + 
  geom_errorbar(aes(ymin=err-se, ymax=err+se), size=1.5, width=.1, position=pd) +
  geom_line(position=pd, size=1.5) + geom_point(position=pd) + scale_y_continuous(limits=errRange) + 
  xlab("Frequency") + ylab("SSE") + ggtitle("Freq x Reg: Taraban & McClelland 1987 A1\n Hid Layer & Learn Rate") +
  facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'TM1987A1_sseavg.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')

# drawpoints
hlsize <- 100; lrnrate <- 5e-2
# get subdata across all drawpoints
frTM1987A1_cross <- subset(frTM1987A1, iter %in% drawpoints)
frTM1987A1_cross <- frTM1987A1_cross[frTM1987A1_cross$hlsize==hlsize & frTM1987A1_cross$lrnrate==lrnrate, ]
# anova test
aovfit2 <- aov(err ~ freq*reg + iter, data=frTM1987A1_cross)
s <- summary(aovfit2); capture.output(s, file=paste(figDir, 'TM1987A1_sseavg_cross', '.txt', sep=""))
frTM1987A1_cross_avg <- summarySE(frTM1987A1_cross, measurevar="err", groupvars=c("freq", "reg", "hlsize", "lrnrate", "iter"), na.rm=TRUE)
errRange <- c(0.0, 200.0)
ggplot(frTM1987A1_cross_avg, aes(x=freq, y=err, linetype=reg, group=reg)) + 
  geom_errorbar(aes(ymin=err-se, ymax=err+se), size=1.5, width=.1, position=pd) +
  geom_line(position=pd, size=1.5) + geom_point(position=pd) + scale_y_continuous(limits=errRange) + 
  xlab("Frequency") + ylab("SSE") + ggtitle("F x R: Strain etal 1995 \n Hid Layer & Learn Rate") +
  facet_wrap(~iter, nrow=2)
ggsave(paste(figDir, 'TM1987A1_sseavg_cross.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')

# draw each point
for(drawpoint in drawpoints){
  txtName <- paste('TM1987A1_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoint, '.txt', sep="")
  aovSub(hlsize, lrnrate, drawpoint, frTM1987A1, txtName, "freq*reg")
}
picName <- paste('TM1987A1_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[1], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[1], frTM1987A1, picName, c(0.0, 5.0), 'Taraban&McClelland 1987A1', "freq*reg")
picName <- paste('TM1987A1_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[2], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[2], frTM1987A1, picName, c(0.0, 4.0), 'Taraban&McClelland 1987A1', "freq*reg")
picName <- paste('TM1987A1_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[3], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[3], frTM1987A1, picName, c(0.0, 3.0), 'Taraban&McClelland 1987A1', "freq*reg")
picName <- paste('TM1987A1_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[4], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[4], frTM1987A1, picName, c(0.0, 3.0), 'Taraban&McClelland 1987A1', "freq*reg")
picName <- paste('TM1987A1_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[5], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[5], frTM1987A1, picName, c(0.0, 2.0), 'Taraban&McClelland 1987A1', "freq*reg")
picName <- paste('TM1987A1_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[6], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[6], frTM1987A1, picName, c(0.0, 2.0), 'Taraban&McClelland 1987A1', "freq*reg")


# Taraban-McClelland-1987-Appendix-A2:
TM1987A2 <- read.csv("Taraban-McClelland-1987-Appendix-A2.csv", na.strings='na')
trTM1987A2 <- subset(tr, tr$S %in% TM1987A2$S); trTM1987A2 <- merge(trTM1987A2, TM1987A2, by = c("S"), all.x = TRUE, all.y = FALSE)
fcTM1987A2 <- subset(trTM1987A2, freq == "H" | freq == "L")
cat(length(unique(fcTM1987A2$S)), '\n')
# 95
# save fcTM1987A2
write.csv(fcTM1987A2, "TM1987A2.csv", row.names=FALSE)

# draw accuracy
ggplot(fcTM1987A2, aes(x=iter, y=accuracy, color=interaction(freq, const))) + scale_x_log10(labels=scinot) + coord_cartesian(xlim=drawrange) + 
  scale_y_continuous(limits=c(0.0, 1.0)) +
  xlab("Training Trials (log10)") + ylab("Avg Acc") + ggtitle("Acc x Trials: Taraban & McClelland 1987 A2\n Hid Layer & Learn Rate") +
  geom_smooth(span=.2, aes(color=interaction(freq, const))) + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'TM1987A2_acu.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')
# draw summed square error
errRange <- c(0.0, 200.0)
ggplot(fcTM1987A2, aes(x=iter, y=err, color=interaction(freq, const))) + scale_x_log10(labels=scinot) + coord_cartesian(xlim=drawrange) + 
  scale_y_continuous(limits=errRange) +
  xlab("Training Trials (log10)") + ylab("Avg Err") + ggtitle("Err x Trials: Taraban & McClelland 1987 A2\n Hid Layer & Learn Rate") +
  geom_smooth(span=.2, aes(color=interaction(freq, const))) + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'TM1987A2_sse.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')

# anova test (for results under a single setting!)
aovfit <- aov(err ~ freq*const + hlsize*lrnrate, data=fcTM1987A2)
s <- summary(aovfit); capture.output(s, file=paste(figDir, 'TM1987A2_sseavg', '.txt', sep=""))
fcTM1987A2_avg <- summarySE(fcTM1987A2, measurevar="err", groupvars=c("freq", "const", "hlsize", "lrnrate"), na.rm=TRUE)
errRange <- c(0.0, 200.0)
ggplot(fcTM1987A2_avg, aes(x=freq, y=err, linetype=const, group=const)) + 
  geom_errorbar(aes(ymin=err-se, ymax=err+se), size=1.5, width=.1, position=pd) +
  geom_line(position=pd, size=1.5) + geom_point(position=pd) + scale_y_continuous(limits=errRange) + 
  xlab("Frequency") + ylab("SSE") + ggtitle("F x C: Taraban & McClelland 1987 A2\n Hid Layer & Learn Rate") +
  facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'TM1987A2_sseavg.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')

# drawpoints
hlsize <- 100; lrnrate <- 5e-2
# get subdata across all drawpoints
fcTM1987A2_cross <- subset(fcTM1987A2, iter %in% drawpoints)
fcTM1987A2_cross <- fcTM1987A2_cross[fcTM1987A2_cross$hlsize==hlsize & fcTM1987A2_cross$lrnrate==lrnrate, ]
# anova test
aovfit2 <- aov(err ~ freq*const + iter, data=fcTM1987A2_cross)
s <- summary(aovfit2); capture.output(s, file=paste(figDir, 'TM1987A2_sseavg_cross', '.txt', sep=""))
fcTM1987A2_cross_avg <- summarySE(fcTM1987A2_cross, measurevar="err", groupvars=c("freq", "const", "hlsize", "lrnrate", "iter"), na.rm=TRUE)
errRange <- c(0.0, 200.0)
ggplot(fcTM1987A2_cross_avg, aes(x=freq, y=err, linetype=const, group=const)) + 
  geom_errorbar(aes(ymin=err-se, ymax=err+se), size=1.5, width=.1, position=pd) +
  geom_line(position=pd, size=1.5) + geom_point(position=pd) + scale_y_continuous(limits=errRange) + 
  xlab("Frequency") + ylab("SSE") + ggtitle("F x R: Strain etal 1995 \n Hid Layer & Learn Rate") +
  facet_wrap(~iter, nrow=2)
ggsave(paste(figDir, 'TM1987A2_sseavg_cross.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')

# draw each point
for(drawpoint in drawpoints){
  txtName <- paste('TM1987A2_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoint, '.txt', sep="")
  aovSub(hlsize, lrnrate, drawpoint, fcTM1987A2, txtName, "freq*const")
}
picName <- paste('TM1987A2_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[1], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[1], fcTM1987A2, picName, c(0.0, 3.0), 'Taraban&McClelland 1987A2', "freq*const")
picName <- paste('TM1987A2_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[2], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[2], fcTM1987A2, picName, c(0.0, 2.0), 'Taraban&McClelland 1987A2', "freq*const")
picName <- paste('TM1987A2_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[3], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[3], fcTM1987A2, picName, c(0.0, 1.0), 'Taraban&McClelland 1987A2', "freq*const")
picName <- paste('TM1987A2_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[4], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[4], fcTM1987A2, picName, c(0.0, 1.0), 'Taraban&McClelland 1987A2', "freq*const")
picName <- paste('TM1987A2_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[5], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[5], fcTM1987A2, picName, c(0.0, 1.0), 'Taraban&McClelland 1987A2', "freq*const")
picName <- paste('TM1987A2_sseavg_H', hlsize, 'L', lrnrate, '_', drawpoints[6], '.png', sep="")
drawSub(hlsize, lrnrate, drawpoints[6], fcTM1987A2, picName, c(0.0, 1.0), 'Taraban&McClelland 1987A2', "freq*const")


# nonwords: Treiman et al. 1990 case:
Tr1990A <- read.csv("Treiman-etal-1990-Appendix.csv")
wordTr1990A <- merge(DFte_merge, Tr1990A, by = c("S"), all.x=TRUE, all.y=FALSE); wordTr1990A <- subset(wordTr1990A, freq == "H" | freq == "L")
xtabs(~freq, data=wordTr1990A)
# freq
# H  L 
# 24 24
teTr1990A <- subset(te, te$O %in% wordTr1990A$O)
teTr1990A <- merge(teTr1990A, Tr1990A, by = c("S"), all.x = TRUE, all.y = FALSE)
fTr1990A <- subset(teTr1990A, freq == "H" | freq == "L")
cat(length(unique(fTr1990A$O)), '\n')
# 48
# save fTr1990A
write.csv(fTr1990A, "Tr1990A.csv", row.names=FALSE)

# draw accuracy
ggplot(fTr1990A, aes(x=iter, y=accuracy, color=freq)) + scale_x_log10(labels=scinot) + coord_cartesian(xlim=drawrange) + 
  scale_y_continuous(limits=c(0.0, 1.0)) +
  xlab("Training Trials (log10)") + ylab("Avg Acc") + ggtitle("Acc x Trials: Treiman etal 1990\n Hid Layer & Learn Rate") +
  geom_smooth(span=.2, aes(color=freq)) + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'Tr1990A_acu.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')
# draw sum squared error
errRange <- c(0.0, 200.0)
ggplot(fTr1990A, aes(x=iter, y=err, color=freq)) + scale_x_log10(labels=scinot) + coord_cartesian(xlim=drawrange) + 
  scale_y_continuous(limits=errRange) +
  xlab("Training Trials (log10)") + ylab("Avg Err") + ggtitle("Err x Trials: Treiman etal 1990\n Hid Layer & Learn Rate") +
  geom_smooth(span=.2, aes(color=freq)) + facet_grid(lrnrate~hlsize)
ggsave(paste(figDir, 'Tr1990A_sse.png', sep=""), dpi = 300, height = 6, width = 12, units = 'in')



##################################################
## see exact words in different testing sets
# Strain et al. 1995A:
wordStr1995A <- merge(DFtr_merge, Str1995A, by = c("S"), all.x=TRUE, all.y=FALSE)
wordStr1995A <- subset(wordStr1995A, freq == "H" | freq == "L")
xtabs(~freq+reg, data=wordStr1995A)
# reg
# freq  E  R
# H 15 14
# L 13 14
unique(wordStr1995A$S[wordStr1995A$freq=="H" & wordStr1995A$reg=="R"])
# [1] best  bill  black bring dark  deal  saw   sense space stay  west  wife  write wrong
unique(wordStr1995A$S[wordStr1995A$freq=="H" & wordStr1995A$reg=="E"])
# [1] blood  break  dead   death  does   done   flow   foot   steak  sure   toward want   war watch worth 
unique(wordStr1995A$S[wordStr1995A$freq=="L" & wordStr1995A$reg=="R"])
# [1] blade blunt deed  ditch dodge dump  sack  sane  scorn scout weed  wick  wisp  yore 
unique(wordStr1995A$S[wordStr1995A$freq=="L" & wordStr1995A$reg=="E"])
# [1] blown  breast debt   dough  dove   dread  scarce suave  swamp  sword  wealth worm   wrath
unique(Str1995A$S[!(Str1995A$S %in% wordStr1995A$S)])
# [1] blister   blunder   boulder   broader   doctor    district  building  greatest  mirror    mercy     monarch   mischief  market    manner    money     measure  
# [17] mustard   mister    monkey    nowhere   morning   method    mother    nothing  pepper    parry     treasure  twofold   picture   training  people    pickle   
# [33] pious     croquet   toughness teacher   trying    police    trouble   wont


# Taraban & McClelland 1987A1:
wordTM1987A1 <- merge(DFtr_merge, TM1987A1, by = c("S"), all.x=TRUE, all.y=FALSE)
wordTM1987A1 <- subset(wordTM1987A1, freq == "H" | freq == "L")
xtabs(~freq+reg, data=wordTM1987A1)
# reg
# freq  E  R
# H 24 24
# L 24 24
unique(wordTM1987A1$S[wordTM1987A1$freq=="H" & wordTM1987A1$reg=="R"])
# [1] best  big   came  class dark  did   fact  got   group him   main  out   page  place see   soon  stop  tell  week  when  which will  with  write
unique(wordTM1987A1$S[wordTM1987A1$freq=="H" & wordTM1987A1$reg=="E"])
# [1] are    both   break  choose come   do     does   done   foot   give   great  have  move   pull   put    says   shall  want   watch  were   what   word   work  
unique(wordTM1987A1$S[wordTM1987A1$freq=="L" & wordTM1987A1$reg=="R"])
# [1] beam  broke bus   deed  dots  float grape lunch peel  pitch pump  ripe  sank  slam  slip  stunt swore trunk wake  wax   weld  wing  with  word 
unique(wordTM1987A1$S[wordTM1987A1$freq=="L" & wordTM1987A1$reg=="E"])
# [1] bowl  broad bush  deaf  doll  flood gross lose  pear  phase pint  plow  rouse sew   shoe  spook swamp swarm touch wad   wand  wash  wool  worm
unique(TM1987A1$S[!(TM1987A1$S %in% wordTM1987A1$S)])


# Taraban-McClelland-1987-Appendix-A2:
wordTM1987A2 <- merge(DFtr_merge, TM1987A2, by = c("S"), all.x=TRUE, all.y=FALSE)
wordTM1987A2 <- subset(wordTM1987A2, freq == "H" | freq == "L")
xtabs(~freq+const, data=wordTM1987A2)
# const
# freq  C  I
# H 24 24
# L 24 23
unique(wordTM1987A2$S[wordTM1987A2$freq=="H" & wordTM1987A2$const=="C"])
# [1] bag   bird  by    clean corn  draw  dust  fast  feet  fine  fish  get   girl  gold  help  high  mile  piece plate rice  rod   sent  skin  such
unique(wordTM1987A2$S[wordTM1987A2$freq=="H" & wordTM1987A2$const=="I"])
# [1] base  bone  but   catch cool  days  dear  five  flat  flew  form  go    goes  grow  here  home  meat  paid  plant roll  root  sand  small speak
unique(wordTM1987A2$S[wordTM1987A2$freq=="L" & wordTM1987A2$const=="C"])
# [1] brisk cane  clang code  cope  dime  fawn  gong  hide  hike  leg   loom  luck  math  mist  mix   moist mole  pail  peach peep  reef  taps  tend 
unique(wordTM1987A2$S[wordTM1987A2$freq=="L" & wordTM1987A2$const=="I"])
# [1] brood cook  cord  cove  cramp dare  fowl  gull  harm  hoe   lash  leaf  loss  mad   moth  mouse mush  pork  pose  pouch rave  tint  toad 
unique(TM1987A2$S[!(TM1987A2$S %in% wordTM1987A2$S)])
# [1] moose