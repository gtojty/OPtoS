# -*- coding: utf-8 -*-
"""
Created on Mon Aug 8 10:36:17 2016

@author: tg422

Select particular words from Coca and Moby dictionaries
"""

import pandas as pd


def writeOP(exp_file, DF, i, Dic, typ):
    if typ == 0:
        # add int to encodList        
        for j in range(0, len(DF[i]), 2):
            encodList = Dic[DF[i][j]]
            line = ""
            for k in range(len(encodList)):
                line = line + str(int(encodList[k])) + " "
            exp_file.write(line + "\n")
    elif typ == 1:
        # no int to encodList        
        for j in range(0, len(DF[i]), 2):
            encodList = Dic[DF[i][j]]
            line = ""
            for k in range(len(encodList)):
                line = line + str(encodList[k]) + " "
            exp_file.write(line + "\n")    

def writeS(exp_file, DF, i, Dic):
    encodList = Dic[DF[i]]
    line = ""
    for k in range(len(encodList)):
        line = line + str(int(encodList[k])) + " "
    exp_file.write(line + "\n")

def writeExp(wordDF, expFileName, probcol, epoch, typ1, st1, end1, typ2, st2, end2, Dic1, Dic2):
    with open(expFileName, "w+") as exp_file:
        cur = 0    
        for i in range(len(wordDF)):
            cur += 1; print "Cur: ", cur        
            # TAG line        
            line = "TAG Word: " + str(wordDF.wordform[i]) + " Rep_O: " + wordDF.Rep_O[i] + " Rep_P: " + wordDF.Rep_P[i] + " Rep_S: '" + str(wordDF.wordform[i]) + "',"
            exp_file.write(line + "\n")
            # PROB line        
            line = "PROB " + str(wordDF.loc[i, probcol])
            exp_file.write(line + "\n")
            # CLAMP line
            if st1 == end1: line = "CLAMP " + typ1 + " " + str(st1) + " EXPANDED"
            else: line = "CLAMP " + typ1 + " " + str(st1) + "-" + str(end1) + " EXPANDED"
            exp_file.write(line + "\n")
            # encoding
            if typ1 == "Ortho": writeOP(exp_file, wordDF.Rep_O, i, Dic1, 0)          
            elif typ1 == "Phono": writeOP(exp_file, wordDF.Rep_P, i, Dic1, 1)
            elif typ1 == "Sem": writeS(exp_file, wordDF.wordform, i, Dic1)
            exp_file.write("\n")
            # TARGET line
            if st2 == end2: line = "CLAMP " + typ2 + " " + str(st2) + " EXPANDED"
            else: line = "TARGET " + typ2 + " " + str(st2) + "-" + str(end2) + " EXPANDED"
            exp_file.write(line + "\n")
            # encoding
            if typ2 == "Ortho": writeOP(exp_file, wordDF.Rep_O, i, Dic2, 0)          
            elif typ2 == "Phono": writeOP(exp_file, wordDF.Rep_P, i, Dic2, 1)
            elif typ2 == "Sem": writeS(exp_file, wordDF.wordform, i, Dic2)
            exp_file.write(";\n")    

         
# ---------------------------------------------- #
# for creating example files: ortho: 8-letter length (3(con) + 2(vow) + 3(con))
#                             sem: 50/100/200/300 semantic items              
# ---------------------------------------------- #
# create LettDic
import string
cand = string.ascii_lowercase
lettList = len(cand)*[0]
LettDic = dict()
for i in range(len(cand)):
    lettListCopy = lettList[:]
    lettListCopy[i] = 1     
    LettDic[cand[i]] = lettListCopy
LettDic['_'] = lettList # filler

# get data file
SemItemList = [50,100,200,300]
for numSemItem in SemItemList:
    wordfileName = './SubAlldisori_' + str(numSemItem) + '.csv'
    wordDF = pd.read_csv(wordfileName)

    # normalize frequencies
    wordDF.sqrt_freq = wordDF.sqrt_freq/(float(sum(wordDF.sqrt_freq)))
    temp = range(0,11,1)    
    bcLambda = [i/10.0 for i in temp]
    for ll in bcLambda:
        colname = 'bcLambda_' + str(ll)
        wordDF.loc[:, colname] = wordDF.loc[:, colname]/(float(sum(wordDF.loc[:, colname])))

    # create semantic dictionary
    SemDic = dict()
    for i in range(len(wordDF)):
        SemDic[wordDF.wordform[i]] = list(wordDF.loc[i,"sem_1":("sem_" + str(numSemItem))])

    # write to example file
    writeExp(wordDF, './Tr_' + str(numSemItem) + '_OtoS_log.txt', 'log_freq', 7, "Ortho", 0, 6, "Sem", 4, 6, LettDic, SemDic)
    writeExp(wordDF, './Tr_' + str(numSemItem) + '_StoS_log5.txt', 'log_freq', 5, "Sem", 0, 0, "Sem", 2, 4, SemDic, SemDic)
    writeExp(wordDF, './Tr_' + str(numSemItem) + '_StoS_log7.txt', 'log_freq', 7, "Sem", 0, 0, "Sem", 2, 4, SemDic, SemDic)
    writeExp(wordDF, './Tr_' + str(numSemItem) + '_OtoS_sqrt.txt', 'sqrt_freq', 7, "Ortho", 0, 6, "Sem", 4, 6, LettDic, SemDic)
    writeExp(wordDF, './Tr_' + str(numSemItem) + '_StoS_sqrt5.txt', 'sqrt_freq', 5, "Sem", 0, 0, "Sem", 2, 4, SemDic, SemDic)
    writeExp(wordDF, './Tr_' + str(numSemItem) + '_StoS_sqrt7.txt', 'sqrt_freq', 7, "Sem", 0, 0, "Sem", 2, 4, SemDic, SemDic)
    # based on different lambda values of boxcox transformation
    temp = range(0,11,1)
    bcLambda = [i/10.0 for i in temp]
    for ll in bcLambda:
        colname = 'bcLambda_' + str(ll)
        writeExp(wordDF, './Tr_' + str(numSemItem) + '_OtoS_' + str(ll) + '.txt', colname, 7, "Ortho", 0, 6, "Sem", 4, 6, LettDic, SemDic)
        writeExp(wordDF, './Tr_' + str(numSemItem) + '_StoS_' + str(ll) + '.txt', colname, 7, "Sem", 0, 0, "Sem", 2, 4, SemDic, SemDic)
