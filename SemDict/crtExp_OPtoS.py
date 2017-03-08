# -*- coding: utf-8 -*-
"""
Created on Mon Aug 8 10:36:17 2016

@author: tg422

Select particular words from Coca and Moby dictionaries
"""

import pandas as pd
import csv


class Dictlist(dict):
    def __setitem__(self, key, value):
        try:
            self[key]
        except KeyError:
            super(Dictlist, self).__setitem__(key, [])
        self[key].append(value)

def saveDict(fn,dict_rap):
    f = open(fn,'wb')
    w = csv.writer(f)
    for key, val in dict_rap.items():
        w.writerow([key, val])
    f.close()
     
def readDict(fn):
    f = open(fn,'rb')
    dict_rap = Dictlist()
    for key, val in csv.reader(f):
        dict_rap[key] = eval(val)
    f.close()
    return(dict_rap)

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
            if st2 == end2: line = "TARGET " + typ2 + " " + str(st2) + " EXPANDED"
            else: line = "TARGET " + typ2 + " " + str(st2) + "-" + str(end2) + " EXPANDED"
            exp_file.write(line + "\n")
            # encoding
            if typ2 == "Ortho": writeOP(exp_file, wordDF.Rep_O, i, Dic2, 0)          
            elif typ2 == "Phono": writeOP(exp_file, wordDF.Rep_P, i, Dic2, 1)
            elif typ2 == "Sem": writeS(exp_file, wordDF.wordform, i, Dic2)
            exp_file.write(";\n")    
     
def crtSem(numSemItem, name1, name2):
    wordfileName = name1 + str(numSemItem) + '.csv'
    wordDF = pd.read_csv(wordfileName)
    expFileName = name2 + str(numSemItem) + '.txt'
    with open(expFileName, "w+") as exp_file:
        for i in range(len(wordDF)):
            print "Cur: ", i+1  
            line = wordDF.wordform[i]
            for j in range(numSemItem):
                line = line + " " + str(wordDF.loc[i,"sem_" + str(1+j)])
            exp_file.write(line + "\n")         

def crtOtoS(numSemItem, name1, name2, LettDic):
    wordfileName = name1 + str(numSemItem) + '.csv'
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
    writeExp(wordDF, name2 + str(numSemItem) + '_OtoS_log.txt', 'log_freq', epoch, "Ortho", st1, end1, "Sem", st2, end2, LettDic, SemDic)
    writeExp(wordDF, name2 + str(numSemItem) + '_OtoS_sqrt.txt', 'sqrt_freq', epoch, "Ortho", st1, end1, "Sem", st2, end2, LettDic, SemDic)
    # based on different lambda values of boxcox transformation
    temp = range(0,11,1)
    bcLambda = [i/10.0 for i in temp]
    for ll in bcLambda:
        colname = 'bcLambda_' + str(ll)
        writeExp(wordDF, name2 + str(numSemItem) + '_OtoS_' + str(ll) + '.txt', colname, epoch, "Ortho", st1, end1, "Sem", st2, end2, LettDic, SemDic)
    
def crtPtoS(numSemItem, name1, name2, PhonDic):
    wordfileName = name1 + str(numSemItem) + '.csv'
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
    writeExp(wordDF, name2 + str(numSemItem) + '_PtoS_log.txt', 'log_freq', epoch, "Phono", st1, end1, "Sem", st2, end2, PhonDic, SemDic)
    writeExp(wordDF, name2 + str(numSemItem) + '_PtoS_sqrt.txt', 'sqrt_freq', epoch, "Phono", st1, end1, "Sem", st2, end2, PhonDic, SemDic)
    # based on different lambda values of boxcox transformation
    temp = range(0,11,1)
    bcLambda = [i/10.0 for i in temp]
    for ll in bcLambda:
        colname = 'bcLambda_' + str(ll)
        writeExp(wordDF, name2 + str(numSemItem) + '_PtoS_' + str(ll) + '.txt', colname, epoch, "Phono", st1, end1, "Sem", st2, end2, PhonDic, SemDic)
        
def crtStoS(numSemItem, name1, name2):
    wordfileName = name1 + str(numSemItem) + '.csv'
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
    writeExp(wordDF, name2 + str(numSemItem) + '_StoS_log.txt', 'log_freq', epoch, "Sem", st1, end1, "Sem", st2, end2, SemDic, SemDic)
    writeExp(wordDF, name2 + str(numSemItem) + '_StoS_sqrt.txt', 'sqrt_freq', epoch, "Sem", st1, end1, "Sem", st2, end2, SemDic, SemDic)
    # based on different lambda values of boxcox transformation
    temp = range(0,11,1)
    bcLambda = [i/10.0 for i in temp]
    for ll in bcLambda:
        colname = 'bcLambda_' + str(ll)
        writeExp(wordDF, name2 + str(numSemItem) + '_StoS_' + str(ll) + '.txt', colname, epoch, "Sem", st1, end1, "Sem", st2, end2, SemDic, SemDic)

 
# ---------------------------------------------- #
# record homophones
numSemItem = 50; wordfileName = './rawdata/DisOri_' + str(numSemItem) + '.csv'
wordDF = pd.read_csv(wordfileName)
homo_temp = Dictlist()
for i in range(len(wordDF)):
    homo_temp[wordDF.Rep_P[i]] = wordDF.wordform[i]
homo = Dictlist()
for rep_p in homo_temp.keys():
    if len(homo_temp[rep_p]) > 1:
        homo[rep_p] = homo_temp[rep_p]
saveDict('./rawdata/Homo.csv', homo)

# sem.txt and sem_nohomo.txt
SemItemList = [50,100,200,300]
for numSemItem in SemItemList:
    crtSem(numSemItem, './rawdata/DisOri_', './sem_')
    crtSem(numSemItem, './rawdata/DisOri_nohomo_', './sem_nohomo_')

# ---------------------------------------------- #
# O to S:
# for creating example files: ortho: 8-letter length (3(con) + 2(vow) + 3(con))
#                             sem: 50/100/200/300 semantic items              
# ---------------------------------------------- #
# set up epoch settings
epoch = 7; st1, end1 = 0, 6; st2, end2 = 4, 6
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
    crtOtoS(numSemItem, './rawdata/DisOri_', './Tr_', LettDic)
    crtOtoS(numSemItem, './rawdata/DisOri_nohomo_', './Tr_nohomo_', LettDic)

# ---------------------------------------------- #
# P to S:
# for creating example files: phon: 7-phoneme length (3(con) + 1(vow) + 3(con))
#                             sem: 50/100/200/300 semantic items              
# ---------------------------------------------- #
# set up epoch settings
epoch = 7; st1, end1 = 0, 6; st2, end2 = 4, 6
# Based on Harm (1998)
# encoding of phonemes:
phonDF = pd.read_csv('./rawdata/phon_Harm1998.txt', sep=' ', header=None)
phonDF.columns = ['Symbol', 'Labial', 'Dental', 'Alveolar', 'Palatal', 'Velar', 
                  'Glottal' ,'Stop', 'Fricative', 'Affricate', 'Nasal', 'Liquid', 
                  'Glide', 'Voice', 'Front', 'Center', 'Back', 'High', 'Mid', 'Low', 
                  'Tense', 'Retroflex', 'Round', 'Pre y', 'Post y', 'Post w']
PhonDic = dict()
for i in range(len(phonDF)):
    PhonDic[phonDF.loc[i, 'Symbol']] = list(phonDF.loc[i,phonDF.columns[1:]])

# get data file
SemItemList = [50,100,200,300]
for numSemItem in SemItemList:
    crtPtoS(numSemItem, './rawdata/DisOri_', './Tr_', PhonDic)
    crtPtoS(numSemItem, './rawdata/DisOri_nohomo_', './Tr_nohomo_', PhonDic)    

# ---------------------------------------------- #
# S to S:
# for creating example files: sem: 50/100/200/300 semantic items 
#                             sem: 50/100/200/300 semantic items              
# ---------------------------------------------- #
# set up epoch settings
epoch = 7; st1, end1 = 0, 0; st2, end2 = 4, 6
# get data file
SemItemList = [50,100,200,300]
for numSemItem in SemItemList:
    crtStoS(numSemItem, './rawdata/DisOri_', './Tr_')
    crtStoS(numSemItem, './rawdata/DisOri_nohomo_', './Tr_nohomo_')  
    