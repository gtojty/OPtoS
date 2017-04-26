#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <mikenet/simulator.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/types.h>

#include "model.h"

#define _FileLen 100
#define _Rand0_1 rand()/(RAND_MAX+1.0)
#define _One 1.0
#define _Zero 0.0
#define _Half 0.5

// global parameters
int _numRuns;
char *_weiF;


// functions to get parameter values;
void get_unsignedint(FILE *f, unsigned int *para)
{ // get unsigned integer paramter;
	assert(f!=NULL);
	char *line=malloc(_LineLen*sizeof(char)); assert(line!=NULL);
	char sep[]="\t", *token=NULL;

	fgets(line, _LineLen, f); token=strtok(line, sep);
   	while(token!=NULL) { *para=atoi(token); token=NULL; }
	free(line); line=NULL;
	token=NULL;
}

void get_int(FILE *f, int *para)
{ // get integer paramter;
	assert(f!=NULL);
	char *line=malloc(_LineLen*sizeof(char)); assert(line!=NULL);
	char sep[]="\t", *token=NULL;

	fgets(line, _LineLen, f); token=strtok(line, sep);
   	while(token!=NULL) { *para=atoi(token); token=NULL; }
	free(line); line=NULL;
	token=NULL;
}

void get_double(FILE *f, double *para)
{ // get double paramter;
	assert(f!=NULL);
	char *line=malloc(_LineLen*sizeof(char)); assert(line!=NULL);
	char sep[]="\t", *token=NULL;

	fgets(line, _LineLen, f); token=strtok(line, sep);
   	while(token!=NULL) { *para=atof(token); token=NULL; }
	free(line); line=NULL;
	token=NULL;
}

void get_string(FILE *f, char **s)
{	assert(f!=NULL);
	char *line=malloc(_LineLen*sizeof(char)); assert(line!=NULL);
	char sep[]="\t", *token=NULL;

	fgets(line, _LineLen, f); token=strtok(line, sep);
   	while(token!=NULL) 
		{ *s=malloc((strlen(token)+1)*sizeof(char)); assert(*s!=NULL); 
		  strcpy(*s, token); token=NULL; 
		}
	free(line); line=NULL;
	token=NULL;
}

void readpara(void)
{ // read parameters from para.txt;
	FILE *f=NULL; 
	char *line=malloc(_LineLen*sizeof(char)); assert(line!=NULL);

	if((f=fopen("para_hid.txt","r+"))==NULL) { printf("Can't open para_hid.txt\n"); exit(1); }

	fgets(line, _LineLen, f);	  // read: // Network Parameters
	get_int(f, &_SimType);	// read _SimType; type of simulation; 0, OtoS; 1, PtoS;
	get_int(f, &_tick_StoS);	// read _tick_StoS; number of ticks in one epoch (trial) of stos training; different types of training can happen in different ticks;
	get_int(f, &_tick_OPtoS);	// read _tick_OPtoS; number of ticks in one epoch (trial) of optos training; different types of training can happen in different ticks;
	get_double(f, &_intconst);	// read _intconst; default value is 0.25;
	get_int(f, &_tai);	// read _tai; default value is 1.
	get_double(f, &_epsi);	// read _epsi; episilon value for the activation curve; default value is 0.001;
	get_int(f, &_acttype);	// read _acttype; // LOGISTIC_ACTIVATION (0), TANH_ACTIVATION (1), FAST_LOGISTIC_ACTIVATION (2), LINEAR_ACTIVATION (3), or STEP_ACTIVATION (4); 
	get_int(f, &_errortype); // int _errortype; SUM_SQUARED_ERROR (1) or CROSS_ENTROPY_ERROR (2)
	get_int(f, &_weightnoisetype);	// int _weightnoisetype; NO_NOISE (0), ADDITIVE_NOISE (1), or MULTIPLICATIVE_NOISE (2)
	get_double(f, &_weightnoise);	// double _weightnoise; noise on connection weights;
	get_double(f, &_actnoise);	// double _actnoise; activation noise;
	get_double(f, &_inputnoise);	// double _inputnoise; input noise;
	get_double(f, &_errrad);	// read _errrad; error radius, errors less than it are counted as zero; default value is 0.1;
	get_double(f, &_range);	// read _range; range of initial weights, the initially randomized weights are positive and negative _range;
	get_int(f, &_OrthoPhonS);	// read _OrthoPhonS; size (number of nodes) of the orthographical layer;
	get_int(f, &_HidS);	// read _HidS; size of the hidden layer between the orthographical and semantic layers;
	get_int(f, &_SemS);	// read _SemS; size of the semantic layer; 50, 100, 200, 300;
	get_int(f, &_SemHidS);	// read _SemHidS; size of the hidden layers between semantic layers, this is the cleanup layer;

	fgets(line, _LineLen, f);	// read: // Parameters for semantics
	get_int(f, &_sem_number);	// read  _sem_number; number of semantics in the dictionary; 
	
	fgets(line, _LineLen, f);	// read: // Parameters for file names storing training and testing examples
	get_string(f, &_semF);	// read _semF; file name of the semantics dictionary, which is a list of semantics and their feature values;
	get_string(f, &_exTrF); // read _exTrF; file name of the training examples; 
	
	fgets(line, _LineLen, f);	// read: // Parameters for weights files
	get_int(f, &_numRuns);	// read _numRuns; number of runs in each condition;
	get_string(f, &_weiF);	// read _weiF; file name of the network weights file; 
	
	free(line); line=NULL;
	fclose(f);
	/*
	// print read parameters;
	printf("simtype=%d\n", _SimType);	// read _SimType; type of simulation; 0, OtoS; 1, PtoS;
	printf("tick_StoS=%d\n", _tick_StoS);	// read _tick_StoS; number of ticks in one epoch (trial) of stos training; different types of training can happen in different ticks;
	printf("tick_OPtoS=%d\n", _tick_OPtoS);	// read _tick_OPtoS; number of ticks in one epoch (trial) of optos training; different types of training can happen in different ticks;
	printf("intconst=%f\n", _intconst);	// read _intconst; default value is 0.25;
	printf("tai=%d\n", _tai);	// read _tai; default value is 1.
	printf("epsi=%f\n", _epsi);	// read _epsi; episilon value for the activation curve; default value is 0.001;
	printf("acttype=%d\n", _acttype);	// read _acttype; // LOGISTIC_ACTIVATION (0), TANH_ACTIVATION (1), FAST_LOGISTIC_ACTIVATION (2), LINEAR_ACTIVATION (3), or STEP_ACTIVATION (4); 
	printf("errortype=%d\n", _errortype); // int _errortype; SUM_SQUARED_ERROR (1) or CROSS_ENTROPY_ERROR (2)
	printf("weightnoisetype=%d\n", _weightnoisetype);	// int _weightnoisetype; NO_NOISE (0), ADDITIVE_NOISE (1), or MULTIPLICATIVE_NOISE (2)
	printf("weightnoise=%f\n", _weightnoise);	// double _weightnoise; noise on connection weights;
	printf("actnoise=%f\n", _actnoise);	// double _actnoise; activation noise;
	printf("inputnoise=%f\n", _inputnoise);	// double _inputnoise; input noise;
	printf("errrad=%f\n", _errrad);	// read _errrad; error radius, errors less than it are counted as zero; default value is 0.1;
	printf("range=%f\n", _range); // read _range; range of initial weights, the initially randomized weights are positive and negative _range;
	printf("OrthoPhon=%d\n", _OrthoPhonS);	// read _OrthoPhonS; size (number of nodes) of the orthographical layer;
	printf("HidS=%d\n", _HidS); // read _HidS; size of the hidden layer between the orthographical and semantic layers;
	printf("SemS=%d\n", _SemS);	// read _SemS; size of the semantic layer; 50, 100, 200, 300;
	printf("SemHidS=%d\n", _SemHidS);	// read _SemHidS; size of the hidden layers between semantic layers, this is the cleanup layer;

	printf("sem_number=%d\n", _sem_number);	// read _sem_number; number of semantics in the dictionary;

	printf("semF=%s\n", _semF); 	// read _semF; file name of the semantics dictionary, which is a list of semantics and their feature values;
	printf("exTrF=%s\n", _exTrF); // read _exTrF; file name of the training examples;

	printf("numRuns=%d\n", _numRuns);	// read _numRuns; number of runs in each condition;
	printf("weiF=%s\n", _weiF);	// read _weiF; file name of the network weights file; 
	*/
}

// main function;
void main(int argc,char *argv[])
{ // main function: initialize network, and train, and calculate parameters;
  	int i, j, k;
	Example *ex=NULL;
	char *subDirect=NULL, *weightFName=NULL, *resFName=NULL;
	FILE *resF=NULL;
	Real *hidOut=NULL;
	char sep[_FileLen];	

	readpara(); // reading network parameters and parameters for running;	

	announce_version(); setbuf(stdout, NULL); 
	mikenet_set_seed(0);	// set up seed for mikenet

	load_sem(_semF);	// initialize phonemes;

	build_model(_tick_OPtoS); printf("No. Conns: %d\n", count_connections(reading));	  // build up the network;
	train_exm=load_examples(_exTrF, _tick_OPtoS);
		  
	for(i=1;i<=_numRuns;i++)
		{ // set up subDirect;
		  subDirect=malloc((strlen("./")+2+(int)(log10((double)(_numRuns))+1)+1)*sizeof(char)); assert(subDirect!=NULL);
		  strcpy(subDirect, "./"); sprintf(sep, "%d", i); strcat(subDirect, sep); strcat(subDirect, "/");

		  weightFName=malloc(_FileLen*sizeof(char)); assert(weightFName!=NULL);
		  strcpy(weightFName, subDirect); strcat(weightFName, "/"); strcat(weightFName, _weiF);

		  load_weights(reading, weightFName);		  

		  resFName=malloc(_FileLen*sizeof(char)); assert(resFName!=NULL);
		  strcpy(resFName, subDirect); strcat(resFName, "/"); strcat(resFName, _weiF);
		  strcat(resFName, "_hidout.txt");
		  if((resF=fopen(resFName,"a+"))==NULL) { printf("Can't open %s\n", resFName); exit(1); }

		  printf("Recording Hidden Layer Output to %s\n", resFName);
		  // record hidden layer output;
		  for(j=0;j<train_exm->numExamples;j++)
   		 	{ ex=&train_exm->examples[j];	// get each example;
      		  crbp_forward(reading,ex);	// put to the network;

			  hidOut=malloc(_HidS*sizeof(Real)); assert(hidOut!=NULL);
			  for(k=0;k<_HidS;k++)
				hidOut[k]=hidden->outputs[_tick_OPtoS-1][k];	// get output from the network;
	
			  // store results
			  fprintf(resF, "%s", _sem[j].name);
			  for(k=0;k<_HidS;k++)
			  	fprintf(resF, "\t%5.3f", hidOut[k]);
			  fprintf(resF, "\n");			  
		  	}
		  
		  fclose(resF); resF=NULL;
		  printf("Done!\n");

		  // release memory
		  free(resFName); resFName=NULL;
		  free(weightFName); weightFName=NULL;
		  free(subDirect); subDirect=NULL;
		}

	// free network and semantic list;
	free(train_exm); train_exm=NULL;
	free_net(reading); reading=NULL;
	//delete_sem();	// empty _sem;
}
