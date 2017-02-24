---
Author: Tao Gong
Title: Document Use of OtoP Simulation
Affiliation: Haskins Laboratories
output: pdf_document
---

This repository contains code for a neural network (implemented in
[Mikenet](http://www.cnbc.cmu.edu/~mharm/research/tools/mikenet/))
that learns Orthography to Phonology mappings.

The rest sketches how to compile and run the simulation in three
contexts: on a local workstation; on the Yale HPC's Grace cluster; on
the Yale HPC's Omega cluster.

In each case, we assume that the Mikenet library itself has already
been downloaded and compiled on the target platform. See ./Mikenet/MikeNet_notes.txt
and installation packages there for installation issues of Mikenet. 

## Local Workstation

#### Compilation

The codes for the model is in the folder ./code. The model is compiled and run under Linux (Mint 17), with Mikenet package is installed. The source codes include: model.h, model.c, and
OtoP.c.

The model implements a multi-layer neural network from orthography to phonology. The model can be trained in two aspects: training the mapping from orthography to phonology (OtoP) and training the cleanup units in a hidden layer between the phonological output layer and itself (PtoP). The second type of trainning can occur before the first type of training, by setting related parameters during the running of the model. 

To compile an executable file, type: `make -f Makefile` in command
line. This will generate the exe file called *OtoP*.

To clean previous exe file, type: `make -f Makefile clean`. This step
is optional.

#### Running the Simulation

In order to run a simulation, put the exe file (OtoP), parameter file
(para.txt), phoneme dictionary (phon.txt, see ./dictionary for definition
of phonological representations of phonemes following two types of feature
vectors), and training and testing examples (Tr#.txt and Te#.txt, see ./dictionary for 
the examples following the two types of phonological representations
) into the same directory.

para.txt has the following format:

> // Network Parameters

> 1	// int _tai;

> 7	// int _tick;

> 0.25	// double _intconst;

> 1e-3	// double _epsi;

> ...

The first line is a comment line; in each of the following lines, the
format is: value + \t + // type and name of the parameter.  One can
easily change the value of each parameter to fit in new condition.

Parameters in this model are from four categories: parameters for the network (e.g., parameters specifying the number of nodes in different layers of the network and parameters specifying the settings about the activation curve, way of calculating training error, and noise type, etc.), parameters for phonemes (e.g., parameters specifying the number of phonemes and the number of features in each phoneme), parameters for file names (e.g., parameters specifying the names of the txt files of phoneme inventory, training and testing examples), and parameters for running (e.g., parameters specifying the number of training, the sampling frequency, the way to calculate training and testing accuracies, etc.). For each parameter, there is a brief description of its meaning or default and possible values after "//". 

The parameters for running can also be assigned using the shell command based on different arguments (see below). This way of assignment can override the original settings in para.txt.

There are two ways of running the model:

1. Using exe file, type: ./OtoP. 

   One can specify some model parameters for running as command line arguments
   when calling the executable (OtoP): 

   ```
   ./OtoP -seed SEED -runmode RUNMODE -iter ITER -rep REP -iter_ptop ITERPtoP -rep_ptop REPPtoP -samp SAMP -met MET -vthres VTHRES -recvec RECVEC
   ```

   There are default values for each argument, so one can
   specify all or only some of them. Specifying these parameters can be done either in para.txt or via the above arguments when calling the executable (OtoP). All the arguments are optional. If no arguments are provided, the code will use the values set in para.txt.

   * SEED: random seed to be used in that run. Default value is 0 (randomly assigning a seed during the run);

   * RUNMODE: mode of running: 0, directly OtoP training; 1, directly PtoP training; 2, OtoP training after PtoP training;
   
   * ITER: number of total iterations (trainings). Default value is 50000;

   * REP: sampling frequency for recording the results (after how many trainings to record the results). Default value is 1000;
   
   * ITERPtoP: number of total iterations during PtoP training. Default value is 50000;
   
   * REPPtoP: sampling frequency for recording the results during PtoP training. Default value is 1000; 

   * SAMP: sampling method (0: liner; 1: logarithm-like). If SAMP is
     set to 1, REP is no longer useful. Default value is 0;

   * MET: method for determining which phonemen matches the
     activation: 0: use the smallest vector-based Euclidean distance
     between the output and the phoneme; 1, determines whether the bit
     differences between the output and the phonemen are all within
     certain threshold (VTHRES). Default value is 0;

   * VTHRES: if MET is 1, the bit difference threshold for determining
     which phoneme matches the activation. Default value is 0.5;
     
   * RECVEC: whether (1) or not (0) record vector values of the output phonemes of training and testing examples. Defaluse value is 0;  

   The executable will prompt the user to input an integer, which will
   be used as a folder name. Files containing the information about the simulation results
   will be stored there.
   
   * seed.txt: store random seed in that run;

   * weights.txt.gz: zipped connection weights of the trained
     network;
     
   * weights\_ptop.txt.gz: zipped connection weights of the trained network after PtoP training; These connection weights will be loaded before OtoP training. This file is created when PtoP training is included (by setting PTOP to 1 during running or setting _ptop to 1 in para.txt);

   * output.txt: network training errors and training and testing accuracies at
     each sampling point of the OtoP training;
  
   * output\_ptop.txt: network training errors and training accuracies at each sampling point of the PtoP training. This file is created when PtoP training is included (by setting RUNMODE to 1 during running or setting _runmode to 1 in para.txt);

   * itemacu\_tr.txt: item-based OtoP accuracy based on the training data
     (training\_examples.txt) at each sampling point;

   * itemacu\_te.txt: item-based OtoP accuracy based on the testing data
     (so far same as the training data) at each sampling point;
     
   * itemacu\_tr\_ptop.txt: item-based PtoP accuracy based on the training data
     (training\_examples.txt) at each sampling point;

   * itemacu\_te\_ptop.txt: item-based PtoP accuracy based on the testing data
     (so far same as the training data) at each sampling point;   
     
   * trainfreq.txt: the accumulated number of times each training example is chosen for OtoP training at each sampling point;
   
   * trainfreq\_ptop.txt: the accumulated number of times each training example is chosen for PtoP training at each sampling point;
   
   * outphonTr.txt: phonemes activated for each OtoP training example at each sampling point;
   
   * outphonTe.txt: phonemes activated for each OtoP testing example at each sampling point;
   
   * outphonTr\_ptop.txt: phonemes activated for each PtoP training example at each sampling point;
   
   * outphonTe\_ptop.txt: phonemes activated for each PtoP testing example at each sampling point;
   
   * outphonTrVec.txt: vector values of activation for each OtoP training example at each sampling point. This file is created when RECVEC is 1;
   
   * outphonTeVec.txt: vector values of activation for each OtoP testing example at each sampling point. This file is created when RECVEC is 1;

   * outphonTrVec\_ptop.txt: vector values of activation for each PtoP training example at each sampling point. This file is created when RECVEC is 1;
   
   * outphonTeVec\_ptop.txt: vector values of activation for each PtoP testing example at each sampling point. This file is created when RECVEC is 1;
   
   While the model runs, it will also print to the screen overall
   error and average training/testing accuracies at each sampling
   point. Sampling points are places where the performances of 
   network are evaluated. They are evenly (linear) or nonevenly 
   (log-like, see below for running the model) distributed among
   the total number of training.

2. Using shell script, put SerRunLoc.sh into the same folder with the
   exe file, para.txt, phon.txt, Tr#.txt and Te#.txt. On-screen
   outputs will be stored in *.log files.

   This way of running allows user to set up a number of runs each
   having a different random seed. The computer will start each run
   serially, and store the results in the corresponding subfolders (1
   to N, N is the number of runs preset).

   type: `sh SerRunLoc.sh NUM RUNMODE LOG ITER REP ITERPtoP REPPtoP SAMP MET VTHRES RECVEC`

   * NUM: number of runs to be conducted, each using a different
     random seed. This argument must be given;
   * LOG: phrase for clarifying the log file name; 
   * The other arguments are the same as above and optional.

## Yale HPC

On-screen outputs as in the first way of running will be stored in
*.log files.

### Using Grace

#### Compilation

Note that MikeNet has to be installed on Grace before it can be linked
into an executable.
	
1. copy msf.sh, *.c, *.h, Makefile, para.txt, phon.txt, Tr#.txt, Te#.txt
   into the working directory (note that you can change the names of phon.txt, Tr#.txt and Te#.txt in para.txt);

2. load a module for GCC: $ module load Langs/GCC

3. load a module for MikeNet: $ module load Libs/MikeNet

4. compile the source code to exe file: $ make -f Makefile (to clean:
   make -f Makefile clean). Once the code is compiled, use the same
   exe file with different para.txt in different conditions, no need
   recompilation.

#### Running the Simulation

1. set up the parallel running via msf.sh:

2. use "chmod +rwx msf.sh" to change msf.sh permission

3. set up tasklist_*mode*.txt with commands like this (repeat as needed):
   
   ```
   cd ~/workDirec; ./msf.sh 1 1 _PtoP; ./msf.sh 1 2 _OtoP
   cd ~/workDirec; ./msf.sh 2 1 _PtoP; ./msf.sh 2 2 _OtoP
   cd ~/workDirec; ./msf.sh 3 1 _PtoP; ./msf.sh 3 2 _OtoP
   cd ~/workDirec; ./msf.sh 4 1 _PtoP; ./msf.sh 4 2 _OtoP
   ```

   And so on. *mode* here could be \_OtoP or \_PtoP\_OtoP. 

   As shown, this example would run 4 simulations, each first having PtoP training 
   and then having OtoP training.

   You can use a command like the following to automatically generate
   tasklist.txt:

   ```
   sh genTasklist.sh NUMRUN WORKDIREC RUNMODE1 LOG1 RUNMODE2 LOG2
   ```

   * NUMRUN: total number of runs. This argument must be given;

   * WORKDIREC: working directory of the code. Once the code is running, 
     subfolders will be created here for storing results. This argument must be given;

   * RUNMODE1 and LOG1: specify the runmode and log file name; If there are only RUNMODE1 and LOG1 specified, the created tasklist file will be tasklist\_LOG2.txt; if RUNMODE1, LOG1, RUNMODE2, LOG2 are all specified, the created tasklist file will be tasklist\_PtoP\_OtoP.txt.
   
   * RUNMODE2 and LOG2: same as above, but they are used to specify the second msf.sh command. These two arguments are optional. 
	 
4. run the results via SimpleQueue

   ```
   module load Tools/SimpleQueue
   sqCreateScript -n 4 -W 24:00 tasklist.txt > job.sh
   bsub < job.sh
   ```

   As shown, this example recruits 4 nodes to run for 24
   hours. Note that the total number of runs has to be a multipler of 4.

5. You can check job status thus: 
   ```
   bjobs; To kill a job: $ bkill job_ID
    ```

### Using Omega

#### Compilation

Note that MikeNet has to be installed on Omega before it can be linked
into an executable.

1. same as for Grace.

2. load the module for GCC: `module load Langs/GCC/4.5.3`

3. same as for Grace.

4. same as for Grace.

#### Running a Simulation

1. same as for Grace.

2. same as for Grace.

3. To set up tasklist.txt for use on Omega, add `module load
   Langs/GCC/4.5.3;` to the front of each line in tasklist.txt
   from Grace

   You can use a command like the following to automatically generate
   tasklist.txt:

   ```
   sh genTasklist_Omega.sh NUMRUN WORKDIREC RUNMODE1 LOG1 RUNMODE2 LOG2
   ```

   * NUMRUN: total number of runs. This argument must be given;
   * WORKDIREC: working directory of the code. This argument must be given;

   The other arguments are the same as for Grace, and RUNMODE2 and LOG2 are optional.
      
4. run the results via SimpleQueue
   ```
   module load Tools/SimpleQueue
   sqCreateScript -n 3 -w 24:00:00 tasklist.txt > job.sh
   qsub < job.sh
   ```

   As shown, this example recruits 3 nodes (8 cpus each) to run for 24
   hours. Note that the total number of runs has to be a multipler of
   24.

5. check status of a job this:

   ```
   qstat -u USER; to kill a job: $ qdel job_ID
   ```
