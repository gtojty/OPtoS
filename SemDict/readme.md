# Document Use of Derivation of OPtoS Dictionary

This file documents use of GloVe: Global Vectors for Word Representation
(http://nlp.stanford.edu/projects/glove/) for the purpose of building a 
training dictionary for use in an OPtoS learning simulation built in MikeNet. 

Words selected for inclusion in the training dictionary are monosyllabic 
and (mostly) mono-morphemic. In our dataset, there are in total 4005 words represented by
50, 100, 200, or 300 semantic features. The data files are stored in ./rawdata. There are 
two sets of words. DisOri\_*.csv each store 4005 words and their semantic feature values
(columns Sem\_\* store binary feature values (0 or 1), and columns Sem\_\*\_ori store float values
of semantic features from the GloVe project). DisOri_nohomo_*.csv store 3627 words without 
homophones. In these csv files, there are columns recording the occurring frequencies of these
words based on the COCA databset (http://corpus.byu.edu/coca/). There are columns storing 
respectively teh raw frequencies, normalized frequencies, logarithmic frequencies (base e) 
and square root frequencies. In addition, there are boxcox transformed frequencies with 
lambda values from 0.0 to 1.0. Homophones among the 4005 words are stored in Homo.csv.   

## Details of steps from Moby/CoCa to MikeNet OtoP Dictionary
There are two types of dictionaries respectively for OtoS and PtoS training: 

1. Orthographical dictionaries use simple 26-feature vectors to represent 26 English syllables. 

2. Phonological representations follow Harm (1998) (see phon_Harm1998.txt for phonological features
defined for each phoneme). 

The Python code (crtExp_OPtoS.py) helps generate the dictionaries for the model, there are dictionaries 
based on the full list of words and the list without homophones, the generated dictionaries are stored
respectively in the folders All and Nohomo. In each folder, there are subfolders storing the dictionaries
generated based on the 50, 100, 200, or 300 semantic features. In each subfolder, there are three types
of dictionaries:

1. Dictionaries based on log-transformed frequencies (\*\_log.txt)

2. Dictionaries based on square-root frequencies (\*\_sqrt.txt)

3. Dictionaries based on boxcox transformed frequencies (\*\_0.0...1.0.txt in subfolder boxcox)

There are three groups of dictionaries respectively used for three types of training.

1. Dictionaries for O(rthography)toS(emantics) training (\*OtoS\*.txt)

2. Dictionaries for P(honology)toS training (\*PtoS\*.txt)

3. Dictionaries for StoS training (\*StoS\*.txt)

For created dictionaries, we use the same tick setting of the OtoP training model (https://github.com/gtojty/OtoP). 
For OtoS and PtoS trainings, the unit time is divided into 7 ticks, in ticks 0 to 6, the inputs will be clamped to
the O or P items, to accelerate training, the outputs will be compared with the target S items in ticks 4 to 6.
For StoS training, the unit time is divided into 7 tickts, in ticks 0, the inputs are clamped to the S items, in tickts 4 to 6, the outputs will be compared with the same S items. 