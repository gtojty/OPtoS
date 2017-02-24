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

// parameters for recording timepoints, total iteration, and seed;
unsigned int _seed=0;
int _runmode=0;	// 0, directly OtoP training; 1, directly PtoP training; 2, OtoP reading by loading weights from PtoP training results;
unsigned int _iter=5e4;	// total number of training;
unsigned int _rep=1e3;	// sampling frequency; 
unsigned int _iter_ptop=5e4;	// total number of ptop training;
unsigned int _rep_ptop=1e3; // sampling frequency during ptop training;
int _samp_method=0;	// method to do sampling; linear (0) or logarithm-like (1) sampling;
int _v_method=0;	// method to translate output; based on smallest Euclidean-distance (0) or vector range (1);
double _v_thres=0.5;	// if _v_method=0, the threshold used for vector range method;
int _recVec=0;	// whether recording output and hidden layers' vectors (1) or not (0);

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

	if((f=fopen("para.txt","r+"))==NULL) { printf("Can't open OverAllPara.txt\n"); exit(1); }

	fgets(line, _LineLen, f);	  // read: // Network Parameters
	get_int(f, &_tick_PtoP);	// read _tick_PtoP; number of ticks in one epoch (trial) of ptop training; different types of training can happen in different ticks;
	get_int(f, &_tick_OtoP);	// read _tick_OtoP; number of ticks in one epoch (trial) of otop training; different types of training can happen in different ticks;
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
	get_int(f, &_OrthoS);	// read _OrthoS; size (number of nodes) of the orthographical layer;
	get_int(f, &_HidS);	// read _HidS; size of the hidden layer between the orthographical and phonological layers;
	get_int(f, &_PhonoS);	// read _PhonoS; size of the phonological layer; For Harm & Seidenberg 1999, 77 (7*11); For Harm 1998, 175 (7*25);
	get_int(f, &_PhoHidS);	// read _PhoHidS; size of the hidden layers between phonological layers, this is the cleanup layer;

	fgets(line, _LineLen, f);	// read: // Parameters for phonemes
	get_int(f, &_pho_features);	// read _pho_features; number of features in each phoneme; For Harm & Seidenberg 1999, 11; For Harm 1998, 25;
	get_int(f, &_pho_number);	// read _pho_number; number of phonemes in the dictionary; For Harm & Seidenberg 1999, 36 (24+11+1); For Harm 1998, 39 (24+10+4+1);

	fgets(line, _LineLen, f);	// read: // Parameters for file names storing phonological dictionary and training and testing examples
	get_string(f, &_phoF);	// read _phoF; file name of the phoneme dictionary, which is a list of phonemes and their feature values;
	get_string(f, &_exTrF_PtoP);	// read _exTrF_PtoP; file name of the training examples training phonological cleanup units; TrEM_PtoP_HarmSeidenberg1999.txt or TrEM_PtoP_Harm1998.txt; 
	get_string(f, &_exTeF_PtoP);	// read _exTeF_PtoP; file name of the testing examples testing phonological cleanup units; TeEM_PtoP_HarmSeidenberg1999.txt or TeEM_PtoP_Harm1998.txt; 
	get_string(f, &_exTrF);	// read _exTrF; file name of the training examples; TrEm_HarmSeidenberg1999.txt or TrEm_Harm1998.txt;
	get_string(f, &_exTeF);	// read _exTeF; file name of the testing examples; TeEm_HarmSeidenberg1999.txt or TeEm_Harm1998.txt or TE.txt (for nonwords); 
	
	fgets(line, _LineLen, f);	// read: // Parameters for running
	get_unsignedint(f, &_seed);	// read _seed; random seed for each run; if _seed=0, use random seed;
	get_int(f, &_runmode);	//  read _runmode; 0, directly OtoP training; 1, directly PtoP training; 2, OtoP training by loading weights from PtoP training results; 3, directly OtoP training with interleave PtoP training; 4, OtoP training interleaving with PtoP training by loading weights from PtoP training results;
	get_unsignedint(f, &_iter);	// read _iter; total number of training;
	get_unsignedint(f, &_rep);	// read _rep; sampling frequency during training;
	get_unsignedint(f, &_iter_ptop);	// read _iter_ptop; total number of ptop training;
	get_unsignedint(f, &_rep_ptop);	// read _rep_ptop; sampling frequency during ptop training;
	get_int(f, &_samp_method);	// read _samp_method; sampling method; linear (0) or logarithm-like (1) sampling;
	get_int(f, &_v_method);	// read _v_method; method to translate ouput during training; based on smallest Euclidean-distance (0) or vector range (1);
	get_double(f, &_v_thres); // read _v_thres; if _v_method=0, the threshold used for vector range method;
	get_int(f, &_recVec);	// read _recVec; whether recording output and hidden layers' vectors (1) or not (0);

	free(line); line=NULL;
	fclose(f);
	/*
	// print read parameters;
	printf("tick_PtoP=%d\n", _tick_PtoP);	// read _tick_PtoP; number of ticks in one epoch (trial) of ptop training; different types of training can happen in different ticks;
	printf("tick_OtoP=%d\n", _tick_OtoP);	// read _tick_OtoP; number of ticks in one epoch (trial) of otop training; different types of training can happen in different ticks;
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
	printf("Ortho=%d\n", _OrthoS);	// read _OrthoS; size (number of nodes) of the orthographical layer;
	printf("HidS=%d\n", _HidS); // read _HidS; size of the hidden layer between the orthographical and phonological layers;
	printf("PhonoS=%d\n", _PhonoS);	// read _PhonoS; size of the phonological layer; For Harm & Seidenberg 1999, 77 (7*11); For Harm 1998, 175 (7*25);
	printf("PhoHidS=%d\n",	_PhoHidS);	// read _PhoHidS; size of the hidden layers between phonological layers, this is the cleanup layer;

	printf("pho_features=%d\n", _pho_features);	// read _pho_features; number of features in each phoneme; For Harm & Seidenberg 1999, 11; For Harm 1998, 25;
	printf("pho_number=%d\n", _pho_number);	// read _pho_number; number of phonemes in the dictionary; For Harm & Seidenberg 1999, 36 (24+11+1); For Harm 1998, 39 (24+10+4+1);

	printf("phoF=%s\n", _phoF);	// read _phoF; file name of the phoneme dictionary, which is a list of phonemes and their feature values;
	printf("exTrF_PtoP=%s\n", _exTrF_PtoP);	// read _exTrF_PtoP; file name of the training examples training phonological cleanup units; TrEM_PtoP_HarmSeidenberg1999.txt or TrEM_PtoP_Harm1998.txt; 
	printf("exTeF_PtoP=%s\n", _exTeF_PtoP);	// read _exTeF_PtoP; file name of the testing examples testing phonological cleanup units; TeEM_PtoP_HarmSeidenberg1999.txt or TeEM_PtoP_Harm1998.txt; 
	printf("exTrF=%s\n", _exTrF); // read _exTrF; file name of the training examples; TrEm_HarmSeidenberg1999.txt or TrEm_Harm1998.txt;
	printf("exTeF=%s\n", _exTeF); // read _exTeF; file name of the testing examples; TeEm_HarmSeidenberg1999.txt or TeEm_Harm1998.txt or TE.txt (for nonwords); 
	
	printf("seed=%ld\n", _seed); // read _seed; random seed for each run; if _seed=0, use random seed;
	printf("runmode=%d\n", _runmode); // read _runmode; 0, directly OtoP training; 1, directly PtoP training; 2, OtoP training by loading weights from PtoP training results; 3, directly OtoP training with interleave PtoP training; 4, OtoP training interleaving with PtoP training by loading weights from PtoP training results;
	printf("iter=%ld\n", _iter); // read _iter; total number of training;
	printf("rep=%ld\n", _rep);	// read _rep; sampling frequency during training;
	printf("iter_ptop=%ld\n", _iter_ptop);	// read _iter_ptop; total number of ptop training;
	printf("rep_ptop=%ld\n", _rep_ptop); // read _rep_ptop; sampling frequency during ptop training;
	printf("samp_method=%d\n", _samp_method);	// read _samp_method; sampling method; linear (0) or logarithm-like (1) sampling;
	printf("v_method=%d\n", _v_method); // read _v_method; method to translate ouput during training; based on smallest Euclidean-distance (0) or vector range (1);
	printf("v_thres=%f\n", _v_thres); // read _v_thres; if _v_method=0, the threshold used for vector range method;
	printf("recVec=%d\n", _recVec);	// read _recVec; whether recording output and hidden layers' vectors (1) or not (0);
	*/
}

void readarg(int argc,char *argv[])
{ // read runtime parameters from command line input;
	int i;
	for(i=1;i<argc;i++)
		{ if(strcmp(argv[i],"-seed")==0){ assert(atoi(argv[i+1])>=0); _seed=atol(argv[i+1]); i++; } // set random seed via '-seed' argument;
		  else if(strncmp(argv[i],"-runmode",8)==0){ assert((atoi(argv[i+1])>=0)&&(atoi(argv[i+1])<=4)); _runmode=atoi(argv[i+1]); i++; } // set runmode: 0, directly OtoP training; 1, directly PtoP training; 2, OtoP training by loading weights from PtoP training results; 
		  																																// 3, directly OtoP training with interleave PtoP training; 4, OtoP training interleaving with PtoP training by loading weights from PtoP training results;
		  else if(strncmp(argv[i],"-iter",5)==0){ assert(atoi(argv[i+1])>0); _iter=atoi(argv[i+1]); i++; }	// set total number of training iterations via '-iter' argument;
		  else if(strncmp(argv[i],"-rep",4)==0){ assert(atoi(argv[i+1])>0); _rep=atoi(argv[i+1]); i++; }	// set sampling point during training via '-rep' argument;
		  else if(strncmp(argv[i],"-iter_ptop",10)==0){ assert(atoi(argv[i+1])>0); _iter_ptop=atoi(argv[i+1]); i++; } // set total number of ptop training iteractions via '-iter_ptop' argument;
		  else if(strncmp(argv[i],"-rep_ptop",9)==0){ assert(atoi(argv[i+1])>0); _rep_ptop=atoi(argv[i+1]); i++; }	// set sampling point during ptop training via '-rep_ptop' argument;
		  else if(strncmp(argv[i],"-samp",5)==0){ assert((atoi(argv[i+1])==0)||(atoi(argv[i+1])==1)); _samp_method=atoi(argv[i+1]); i++; }	// set sampling method via '-samp' argument;
		  else if(strncmp(argv[i],"-met",4)==0) { assert((atoi(argv[i+1])==0)||(atoi(argv[i+1])==1)); _v_method=atoi(argv[i+1]); i++; } // set accuracy calculation method via '-met' argument;
		  else if(strncmp(argv[i],"-thres",6)==0) { assert((atof(argv[i+1])>=0.0)||(atof(argv[i+1])<=1.0)); _v_thres=atof(argv[i+1]); i++; }	// set accuracy calculation threshold for vector based method via '-thres' argument;
		  else if(strncmp(argv[i],"-recvec",7)==0) { assert((atoi(argv[i+1])==0)||(atoi(argv[i+1])==1)); _recVec=atoi(argv[i+1]); i++; }	// set recording vector output via '-recvec' argument;
		}
}

// functions for the network training;
float euclid_dist(Real *x1, Real *x2)
{ // calculate euclidean distance between two vectors x1 and x2;
	assert(x1!=NULL); assert(x2!=NULL);
	int i;
  	float dist=0.0;
  	for(i=0;i<_pho_features;i++)
    	dist+=(x1[i]-x2[i])*(x1[i]-x2[i]);
  	return dist;
}

int vect_check(Real *x1, Real *x2)
{ // check vector's bit-based threshold between two vectors x1 and x2;
	assert(x1!=NULL); assert(x2!=NULL);
	int i, inThres=1;
	for(i=0;i<_pho_features;i++)
		{ if(fabs(x1[i]-x2[i])>=_v_thres) { inThres=0; break; }
		}
	return inThres;
}

char getphon(Real *vect, Real *trans)
{ // find phoneme matching vect; 
	assert(vect!=NULL); assert(trans!=NULL); 
	int i, j, ind, MaxDist, numInThres, *InThresSet=NULL, curind;
	char curPhon='=';
	
	switch(_v_method)
		{ case 0: // using phoneme with smallest Euclidean distance to vect as trans;
		  		ind=-1; MaxDist=1e6;
		  		for(i=0;i<_pho_number;i++)
					{ if(euclid_dist(vect,_phon[i].vec)<=MaxDist) { ind=i; MaxDist=euclid_dist(vect,_phon[i].vec); }
					}
		  		assert(ind!=-1);
		  		for(i=0;i<_pho_features;i++)
					trans[i]=_phon[ind].vec[i];
				curPhon=_phon[ind].name;
				break;		
		  case 1: // using phoneme with 0.5 threshold to set trans;
		  		numInThres=0;
		  		for(i=0;i<_pho_number;i++)
					{ if(vect_check(vect,_phon[i].vec)) numInThres++;
		  			}
				if(numInThres==0)
					{ // no such phoneme;
		  	  		  for(i=0;i<_pho_features;i++)
						trans[i]=-2.0;
					}
		  		else if(numInThres==1)
					{ // there is only one phoneme that matches this requirement;
			  		  for(i=0;i<_pho_number;i++)
						{ if(vect_check(vect,_phon[i].vec))
							{ for(j=0;j<_pho_features;j++)
								trans[j]=_phon[i].vec[j];
							  curPhon=_phon[i].name;
							  break;
							}
						}
					}
		  		else
					{ // there are more than one phoneme that match this requirement, randomly select one!
			  		  InThresSet=malloc(numInThres*sizeof(int)); assert(InThresSet!=NULL);
			  		  curind=0;
			  		  for(i=0;i<_pho_number;i++)
						{ if(vect_check(vect,_phon[i].vec)) { InThresSet[curind]=i; curind++; }
						}
			  		  ind=(int)(_Rand0_1*numInThres);
			  		  for(i=0;i<_pho_features;i++)
						trans[i]=_phon[InThresSet[ind]].vec[i];
			  		  curPhon=_phon[InThresSet[ind]].name;
					  free(InThresSet); InThresSet=NULL;
					}
				break;
		 default: break;		
		}
	return(curPhon);
}

Real calacu(Real *out, Real *target, char *transPhon)
{ // calculate accuracy by comparing out with target;
	assert(out!=NULL); assert(target!=NULL); 
	int i, j, same, NoAccu, cur;
	Real *vect=NULL, *trans=NULL, *transout=NULL;	// vect is each segment of out, transout is translated out based on accuMethod;
	char curPhon='=';
		
	// initialize transout
	transout=malloc(_PhonoS*sizeof(Real)); assert(transout!=NULL);
	for(i=0;i<_PhonoS;i++) 
		transout[i]=0.0;
	
	// translate phoneme by phoneme
	cur=0;
	for(i=0;i<_PhonoS;i+=_pho_features)
		{ vect=malloc(_pho_features*sizeof(Real)); assert(vect!=NULL);
		  for(j=0;j<_pho_features;j++)
			vect[j]=out[i+j];
		  trans=malloc(_pho_features*sizeof(Real)); assert(trans!=NULL);
		  for(j=0;j<_pho_features;j++)
		  	trans[j]=0.0;

		  transPhon[cur]=getphon(vect, trans); cur++;		  
		  for(j=0;j<_pho_features;j++)
			transout[i+j]=trans[j];

		  free(vect); vect=NULL; free(trans); trans=NULL;	// release memory for vect and trans;
		}
	
	// check correct translation
	NoAccu=0;
	for(i=0;i<_PhonoS;i+=_pho_features)
		{ same=1;
		  for(j=0;j<_pho_features;j++)
			{ if(transout[i+j]!=target[i+j]) { same=0; break; }
			}
		  if(same==1) NoAccu++;
		}
	free(transout); transout=NULL;	// release memory for transout;
	
	if(NoAccu/(float)(_PhonoS/(float)(_pho_features))<1.0) return 0.0;
	else return 1.0;
}

Real getacu(Net *net, ExampleSet *examples, int ticks, int iter, FILE *f1, char *fName1, FILE *f2, char *fName2, FILE *f3, char *fName3, FILE *f4, char *fName4)
{ // calculate accuracy of the network during otop training;
	assert(net!=NULL); assert(examples!=NULL); assert(ticks!=0);
	assert(f1!=NULL); assert(f2!=NULL); assert(fName1!=NULL); assert(fName2!=NULL); 
	if(_recVec==1) { assert(f3!=NULL); assert(fName3!=NULL); }
	assert(f4!=NULL); assert(fName4!=NULL);
	int i, j;
	Example *ex=NULL;
  	Real *target=NULL, *out=NULL, accu, itemaccu, avgaccu, error, itemerror, avgerror;
	char *transPhon=NULL;	// record translated phonemes;
	
	if((f1=fopen(fName1,"a+"))==NULL) { printf("Can't open %s\n", fName1); exit(1); }
	fprintf(f1,"%d\t%d", iter, examples->numExamples);
	if((f2=fopen(fName2,"a+"))==NULL) { printf("Can't open %s\n", fName2); exit(1); }
	fprintf(f2,"%d\t%d", iter, examples->numExamples);
	if(_recVec==1)
		{ if((f3=fopen(fName3,"a+"))==NULL) { printf("Can't open %s\n", fName3); exit(1); }
		  fprintf(f3,"%d\t%d", iter, examples->numExamples);
		}
	if((f4=fopen(fName4,"a+"))==NULL) { printf("Can't open %s\n", fName4); exit(1); }
	fprintf(f4,"%d\t%d", iter, examples->numExamples);
	
	accu=0.0; error=0.0;
	for(i=0;i<examples->numExamples;i++)
    	{ ex=&examples->examples[i];	// get each example;
      	  crbp_forward(net,ex);	// put to the network;
      	  
		  itemerror=compute_error(net,ex); // calculate item training error;
		  error+=itemerror;	// accumulate item error;

		  // initialize out and target;
		  out=malloc(_PhonoS*sizeof(Real)); assert(out!=NULL); 
		  target=malloc(_PhonoS*sizeof(Real)); assert(target!=NULL);
		  for(j=0;j<_PhonoS;j++)
			{ out[j]=output->outputs[ticks-1][j];	// get output from the network;
			  target[j]=get_value(ex->targets,output->index,ticks-1,j);	// get target from the example;
			}		  
		  // initialize transPhon;
		  transPhon=malloc((int)(_PhonoS/(float)(_pho_features))*sizeof(char)); assert(transPhon!=NULL);
		  for(j=0;j<(int)(_PhonoS/(float)(_pho_features));j++)
		  	transPhon[j]='=';
		  		  
		  itemaccu=calacu(out,target,transPhon);	// caculate item accuracy;
		  accu+=itemaccu;	// accumulate item accuracy;

		  // record results to files;
		  fprintf(f1,"\t%5.3f", itemaccu);	// record item accuracy;
		  
		  // record transPhon; 
		  fprintf(f2,"\t");
		  for(j=0;j<(int)(_PhonoS/(float)(_pho_features));j++)
		  	fprintf(f2,"%c", transPhon[j]);

		  if(_recVec==1)
		  	{ // record output vector;
		  	  fprintf(f3,"\t");
		  	  for(j=0;j<_PhonoS;j++)
		  		fprintf(f3,"%2.1f ", out[j]);
			}		  

		  fprintf(f4, "\t%5.3f", itemerror);	// record item summed square error;
		  
		  free(out); out=NULL; free(target); target=NULL;	// release memory for out and target;
		  free(transPhon); transPhon=NULL;	// release memory for transPhon; 
    	}
	avgerror=error/(float)(examples->numExamples);	// calculate average error;
	avgaccu=accu/(float)(examples->numExamples);	// calculate average accuracy;

	fprintf(f1,"\t%5.3f\n", avgaccu); fclose(f1);	
	fprintf(f2,"\n"); fclose(f2);
	if(_recVec==1) { fprintf(f3,"\n"); fclose(f3); }
	fprintf(f4,"\t%5.3f\n", avgerror); fclose(f4);

  	return avgaccu;
}

void train(Net *net, FILE *f1, char *fName1, FILE *f2, char *fName2, FILE *f3, char *fName3, FILE *f4, char *fName4, 
		FILE *f5, char *fName5, FILE *f6, char *fName6, FILE *f7, char *fName7, FILE *f8, char *fName8, FILE *f9, char *fName9, FILE *f10, char *fName10)
{ // train the network and record the training error and accuracies;
  	assert(net!=NULL); assert(f1!=NULL); assert(f2!=NULL); assert(f3!=NULL); assert(f4!=NULL); assert(f5!=NULL); assert(f6!=NULL); 
	assert(fName1!=NULL); assert(fName2!=NULL); assert(fName3!=NULL); assert(fName4!=NULL); assert(fName5!=NULL); assert(fName6!=NULL);
	if(_recVec==1) 
		{ assert(f7!=NULL); assert(f8!=NULL);
		  assert(fName7!=NULL); assert(fName8!=NULL);
		}
	assert(f9!=NULL); assert(f10!=NULL);
	assert(fName9!=NULL); assert(fName10!=NULL);
	unsigned int iter, count, totiter, rep;
	int rate_int;	// ratio between OtoP and interleaved PtoP training;
	int i, ii, jj, loop, loop_out;	// for logarithm-like sampling;
	int *trainAct=NULL;	// record frequency of occurrence of each example;
  	Real error, error_int, accuTr, accuTe;	// record error, training and testing accuracies;
	Example *ex;
		
	ii=1; jj=0; loop=20; loop_out=80; // for logarithm-like sampling;	
	error=0.0; count=1; accuTr=0.0; accuTe=0.0;
	
	switch(_runmode)
		{ case 0: case 2: case 3: case 4:
				// scratch or interleave OtoP (with PtoP) training;
				// initialize trainAct;
		  		trainAct=malloc(train_exm->numExamples*sizeof(int)); assert(trainAct!=NULL); 
		  		for(i=0;i<train_exm->numExamples;i++) 
					trainAct[i]=0;
		  		// set totiter and rep;
		  		totiter=_iter; rep=_rep;

				// calculate rate between OtoP and interleaved PtoP training;
				if((_runmode==3)||(_runmode==4)) { rate_int=(int)(_iter/_iter_ptop); error_int=0.0; }

				// start training;
				for(iter=1;iter<=totiter;iter++)
					{ // normal OtoP training;
					  ex=get_random_example(train_exm); // randomly select a training example; 
					  crbp_forward(net,ex); // feed the example to the network; now, output is ready;
					  error+=compute_error(net,ex); // accumulate training errors;
					  crbp_compute_gradients(net,ex);	// compute gradients 
					  bptt_apply_deltas(net);	// apply deltas in back propagation;
				
					  trainAct[ex->index]++;	// count the occurrence of each example during training;

					  if((_runmode==3)||(_runmode==4))
					  	{ // interleave PtoP training;
						  if(iter%rate_int==0)
						  	{ ex=get_random_example(train_PtoP_exm); // randomly select a training example; 
					  		  crbp_forward(net,ex); // feed the example to the network;
					  		  error_int+=compute_error(net,ex); // accumulate training errors;
					  		  crbp_compute_gradients(net,ex);	// compute gradients 
					  		  bptt_apply_deltas(net);	// apply deltas in back propagation;
						  	}
					  	}
					  
					  // record status;
					  if(_samp_method==0)
						{ if(count==rep)
							{ error=error/(float)count; // calculate average error;
							  if((_runmode==3)||(_runmode==4)) error_int=error_int/(float)(count/rate_int);

							  accuTr=getacu(net, train_exm, _tick_OtoP, iter, f2, fName2, f5, fName5, f7, fName7, f9, fName9);	// calculate training accuracy;
							  accuTe=getacu(net, test_exm, _tick_OtoP, iter, f3, fName3, f6, fName6, f8, fName8, f10, fName10);	// calculate testing accuracy;

							  if((_runmode==0)||(_runmode==2)) printf("iter=%d\terr=%5.3f\tacuTr=%5.3f\tacuTe=%5.3f\n", iter, error, accuTr, accuTe);	// display status on screen;
							  if((_runmode==3)||(_runmode==4)) printf("iter=%d\terr_o2p=%5.3f\terr_p2p=%5.3f\tacuTr=%5.3f\tacuTe=%5.3f\n", iter, error, error_int, accuTr, accuTe);	// display status on screen;
							  
							  // store parameters and results into f1;
							  if((f1=fopen(fName1,"a+"))==NULL) { printf("Can't open %s\n", fName1); exit(1); }
							  if((_runmode==0)||(_runmode==2)) fprintf(f1, "%d\t%5.3f\t%5.3f\t%5.3f\n", iter, error, accuTr, accuTe); 
							  if((_runmode==3)||(_runmode==4)) fprintf(f1, "%d\t%5.3f\t%5.3f\t%5.3f\t%5.3f\n", iter, error, error_int, accuTr, accuTe); 	
							  fclose(f1);
							  
							  // store trainAct into f4;
							  if((f4=fopen(fName4,"a+"))==NULL) { printf("Can't open %s\n", fName4); exit(1); }
							  fprintf(f4, "%d\t%d", iter, train_exm->numExamples);	
							  for(i=0;i<train_exm->numExamples;i++)
								fprintf(f4, "\t%d", trainAct[i]);
							  fprintf(f4,"\n"); fclose(f4);
							  
							  error=0.0; accuTr=0.0; accuTe=0.0; count=1;	// reset error, accuTr, accuTe, and count;
							  if((_runmode==3)||(_runmode==4)) error_int=0.0;
							}
						  else count++;
						}
					  else if(_samp_method==1)
						{ if((iter!=0)&&((iter==(int)(pow(10.0,ii)+loop*pow(10.0,ii-1)*jj))||(iter%(int)(pow(10.0,ii+1))==0)))
							{ // adjust ii and jj to calculate next step
							  if(iter%(int)(pow(10.0,ii+1))==0) { ii+=1; jj=1; }
							  else
								{ if(jj*loop>=loop_out) jj=1;
								  else jj+=1;
								}
							  // record status; 
							  error=error/(float)count; // calculate average error;
							  if((_runmode==3)||(_runmode==4)) error_int=error_int/(float)(count/rate_int);

							  accuTr=getacu(net, train_exm, _tick_OtoP, iter, f2, fName2, f5, fName5, f7, fName7, f9, fName9);	// calculate training accuracy;
							  accuTe=getacu(net, test_exm, _tick_OtoP, iter, f3, fName3, f6, fName6, f8, fName8, f10, fName10);	// calculate testing accuracy;
				
							  if((_runmode==0)||(_runmode==2)) printf("iter=%d\terr=%5.3f\tacuTr=%5.3f\tacuTe=%5.3f\n", iter, error, accuTr, accuTe);	// display status on screen;
							  if((_runmode==3)||(_runmode==4)) printf("iter=%d\terr_o2p=%5.3f\terr_p2p=%5.3f\tacuTr=%5.3f\tacuTe=%5.3f\n", iter, error, error_int, accuTr, accuTe);	// display status on screen;
							  
							  // store parameters and results into f1;
							  if((f1=fopen(fName1,"a+"))==NULL) { printf("Can't open %s\n", fName1); exit(1); }
							  if((_runmode==0)||(_runmode==2)) fprintf(f1, "%d\t%5.3f\t%5.3f\t%5.3f\n", iter, error, accuTr, accuTe); 
							  if((_runmode==3)||(_runmode==4)) fprintf(f1, "%d\t%5.3f\t%5.3f\t%5.3f\t%5.3f\n", iter, error, error_int, accuTr, accuTe); 	
							  fclose(f1);
							  
							  // store parameters and results into f4;
							  if((f4=fopen(fName4,"a+"))==NULL) { printf("Can't open %s\n", fName4); exit(1); }
							  fprintf(f4, "%d\t%d", iter, train_exm->numExamples);
							  for(i=0;i<train_exm->numExamples;i++)
								fprintf(f4, "\t%d", trainAct[i]);
							  fprintf(f4,"\n"); fclose(f4);
								  
							  error=0.0; accuTr=0.0; accuTe=0.0; count=1;	// reset error, accuTr, accuTe, and count; 
							  if((_runmode==3)||(_runmode==4)) error_int=0.0;
							}
						  else count++;
						}
					}
				break;
		  case 1:
		  		// scratch PtoP training;
		  		// initialize trainAct;
				trainAct=malloc(train_PtoP_exm->numExamples*sizeof(int)); assert(trainAct!=NULL); 
		  		for(i=0;i<train_PtoP_exm->numExamples;i++) 
					trainAct[i]=0;
				// set totiter and sep;
		  		totiter=_iter_ptop; rep=_rep_ptop;

				// start training;
				for(iter=1;iter<=totiter;iter++)
					{ // normal PtoP training;
					  ex=get_random_example(train_PtoP_exm); // randomly select a training example; 
					  crbp_forward(net,ex); // feed the example to the network;
					  error+=compute_error(net,ex); // accumulate training errors;
					  crbp_compute_gradients(net,ex);	// compute gradients 
					  bptt_apply_deltas(net);	// apply deltas in back propagation;
				
					  trainAct[ex->index]++;	// count the occurrence of each example during training;

					  // record status;
					  if(_samp_method==0)
						{ if(count==rep)
							{ error=error/(float)count; // calculate average error;
							  accuTr=getacu(net, train_PtoP_exm, _tick_PtoP, iter, f2, fName2, f5, fName5, f7, fName7, f9, fName9);	// calculate training accuracy;
							  accuTe=getacu(net, test_PtoP_exm, _tick_PtoP, iter, f3, fName3, f6, fName6, f8, fName8, f10, fName10);	// calculate testing accuracy;

							  printf("iter=%d\terr=%5.3f\tacuTr=%5.3f\tacuTe=%5.3f\n", iter, error, accuTr, accuTe);	// display status on screen;
				
							  // store parameters and results into f1;
							  if((f1=fopen(fName1,"a+"))==NULL) { printf("Can't open %s\n", fName1); exit(1); }
							  fprintf(f1, "%d\t%5.3f\t%5.3f\t%5.3f\n", iter, error, accuTr, accuTe); fclose(f1);
							  
							  // store trainAct into f4;
							  if((f4=fopen(fName4,"a+"))==NULL) { printf("Can't open %s\n", fName4); exit(1); }
							  fprintf(f4, "%d\t%d", iter, train_PtoP_exm->numExamples);	
							  for(i=0;i<train_PtoP_exm->numExamples;i++)
								fprintf(f4, "\t%d", trainAct[i]);
							  fprintf(f4,"\n"); fclose(f4);
							  
							  error=0.0; accuTr=0.0; accuTe=0.0; count=1;	// reset error, accuTr, accuTe, and count;
							}
						  else count++;
						}
					  else if(_samp_method==1)
						{ if((iter!=0)&&((iter==(int)(pow(10.0,ii)+loop*pow(10.0,ii-1)*jj))||(iter%(int)(pow(10.0,ii+1))==0)))
							{ // adjust ii and jj to calculate next step
							  if(iter%(int)(pow(10.0,ii+1))==0) { ii+=1; jj=1; }
							  else
								{ if(jj*loop>=loop_out) jj=1;
								  else jj+=1;
								}
							  // record status; 
							  error=error/(float)count; // calculate average error;
							  accuTr=getacu(net, train_PtoP_exm, _tick_PtoP, iter, f2, fName2, f5, fName5, f7, fName7, f9, fName9);	// calculate training accuracy;
							  accuTe=getacu(net, test_PtoP_exm, _tick_PtoP, iter, f3, fName3, f6, fName6, f8, fName8, f10, fName10);	// calculate testing accuracy;
				
							  printf("iter=%d\terr=%5.3f\tacuTr=%5.3f\tacuTe=%5.3f\n", iter, error, accuTr, accuTe);	// display status on screen;
				
							  // store parameters and results into f1;
							  if((f1=fopen(fName1,"a+"))==NULL) { printf("Can't open %s\n", fName1); exit(1); }
							  fprintf(f1, "%d\t%5.3f\t%5.3f\t%5.3f\n", iter, error, accuTr, accuTe); fclose(f1);
							  
							  // store parameters and results into f4;
							  if((f4=fopen(fName4,"a+"))==NULL) { printf("Can't open %s\n", fName4); exit(1); }
							  fprintf(f4, "%d\t%d", iter, train_PtoP_exm->numExamples);
							  for(i=0;i<train_PtoP_exm->numExamples;i++)
								fprintf(f4, "\t%d", trainAct[i]);
							  fprintf(f4,"\n"); fclose(f4);
							
							  error=0.0; accuTr=0.0; accuTe=0.0; count=1;	// reset error, accuTr, accuTe, and count; 
							}
						  else count++;
						}
					}
				break;
		  default: break;		
		}
  	free(trainAct); trainAct=NULL;
}

void crtFName(char **fName, char *subDirect, char *name)
{ // create file name as root plus name;
	assert(name!=NULL);
	*fName=malloc((strlen(subDirect)+2+_FileLen)*sizeof(char)); assert(*fName!=NULL); 
	strcpy(*fName, subDirect); strcat(*fName, name);
}

void initF(FILE **f, char *fName, char *format1, char *format2, int size, char *format3)
{ // initialize the first line of f;
	assert(f!=NULL); assert(fName!=NULL); assert(format1!=NULL);
	int i;
	if((*f=fopen(fName,"w+"))==NULL) { printf("Can't open %s\n", fName); exit(1); }
	fprintf(*f, format1);
	if(format2!=NULL) 
		{ for(i=0;i<size;i++)
			fprintf(*f,format2,i+1);
		}
	if(format3!=NULL) fprintf(*f, format3);
	fclose(*f);	
}

void setF(char **fName, char *subDirect, char *name, FILE **f, char *format1, char *format2, int size, char *format3)
{ // setup fName and f with appropriate headers;
	crtFName(fName, subDirect, name);
	initF(f, *fName, format1, format2, size, format3);
}

void setResF(char *subDirect, char **weightF, FILE **f1, char **outF, FILE **f2, char **itemacuTrF, FILE **f3, char **itemacuTeF, FILE **f4, char **trainfreqF,  
	FILE **f5, char **outPhonTrF, FILE **f6, char **outPhonTeF, FILE **f7, char **outPhonTrVecF, FILE **f8, char **outPhonTeVecF, FILE **f9, char **outPhonErrTrF, FILE **f10, char **outPhonErrTeF)
{ // create file names, actual files, and file headers;
	switch(_runmode)
		{ case 0: case 2: case 3: case 4:
				// record connection weights of the network;
		  		crtFName(weightF, subDirect, "weights.txt");	
		  		// record training error, training accuracy and testing accuracy;
		  		if((_runmode==0)||(_runmode==2)) setF(outF, subDirect, "output.txt", f1, "ITER\tErr_O2P\tAcuTr\tAcuTe\n", NULL, 0, NULL);
				if((_runmode==3)||(_runmode==4)) setF(outF, subDirect, "output.txt", f1, "ITER\tErr_O2P\tErr_P2P\tAcuTr\tAcuTe\n", NULL, 0, NULL);
		  		// record item-based training and testing accuracy;
		  		setF(itemacuTrF, subDirect, "itemacu_tr.txt", f2, "ITER\tNoItem", "\tAcu%d", train_exm->numExamples, "\tAvg\n");
		  		setF(itemacuTeF, subDirect, "itemacu_te.txt", f3, "ITER\tNoItem", "\tAcu%d", test_exm->numExamples, "\tAvg\n");
		  		// record accumulative occurring frequency of training examples during training;
		  		setF(trainfreqF, subDirect, "trainfreq.txt", f4, "ITER\tNoItem", "\tF%d", train_exm->numExamples, "\n");
		  		// record output phonemes of training and testing examples;
		  		setF(outPhonTrF, subDirect, "outphonTr.txt", f5, "ITER\tNoItem", "\tPhon%d", train_exm->numExamples, "\n");
		  		setF(outPhonTeF, subDirect, "outphonTe.txt", f6, "ITER\tNoItem", "\tPhon%d", test_exm->numExamples, "\n");
		  		// record output vectors of training and testing examples;
		  		if(_recVec==1) 
					{ setF(outPhonTrVecF, subDirect, "outphonTrVec.txt", f7, "ITER\tNoItem", "\tPV%d", train_exm->numExamples, "\n");		  
		  	  		  setF(outPhonTeVecF, subDirect, "outphonTeVec.txt", f8, "ITER\tNoItem", "\tPV%d", test_exm->numExamples, "\n");
					}
				// record output errors of phonemes;
				setF(outPhonErrTrF, subDirect, "outphonErrTr.txt", f9, "ITER\tNoItem", "\tErr%d", train_exm->numExamples, "\tAvg\n");		  
		  	  	setF(outPhonErrTeF, subDirect, "outphonErrTe.txt", f10, "ITER\tNoItem", "\tErr%d", test_exm->numExamples, "\tAvg\n");
				break;
		  case 1: 
		  		// record connection weights of the network;
		  		crtFName(weightF, subDirect, "weights_ptop.txt");	
		  		// record training error, training accuracy and testing accuracy;
		  		setF(outF, subDirect, "output_ptop.txt", f1, "ITER\tErr\tAcuTr\tAcuTe\n", NULL, 0, NULL);
		  		// record item-based training and testing accuracy;
		  		setF(itemacuTrF, subDirect, "itemacu_tr_ptop.txt", f2, "ITER\tNoItem", "\tAcu%d", train_PtoP_exm->numExamples, "\tAvg\n");
		  		setF(itemacuTeF, subDirect, "itemacu_te_ptop.txt", f3, "ITER\tNoItem", "\tAcu%d", test_PtoP_exm->numExamples, "\tAvg\n");
		  		// record accumulative occurring frequency of training examples during training;
		  		setF(trainfreqF, subDirect, "trainfreq_ptop.txt", f4, "ITER\tNoItem", "\tF%d", train_PtoP_exm->numExamples, "\n");
		  		// record output phonemes of training and testing examples;
		  		setF(outPhonTrF, subDirect, "outphonTr_ptop.txt", f5, "ITER\tNoItem", "\tPhon%d", train_PtoP_exm->numExamples, "\n");
		  		setF(outPhonTeF, subDirect, "outphonTe_ptop.txt", f6, "ITER\tNoItem", "\tPhon%d", test_PtoP_exm->numExamples, "\n");
		  		// record output vectors of training and testing examples;
		  		if(_recVec==1) 
					{ setF(outPhonTrVecF, subDirect, "outphonTrVec_ptop.txt", f7, "ITER\tNoItem", "\tPV%d", train_PtoP_exm->numExamples, "\n");		  
		  	  		  setF(outPhonTeVecF, subDirect, "outphonTeVec_ptop.txt", f8, "ITER\tNoItem", "\tPV%d", test_PtoP_exm->numExamples, "\n");
					}
				// record output errors of phonemes;
				setF(outPhonErrTrF, subDirect, "outphonErrTr.txt", f9, "ITER\tNoItem", "\tErr%d", train_exm->numExamples, "\tAvg\n");		  
		  	  	setF(outPhonErrTeF, subDirect, "outphonErrTe.txt", f10, "ITER\tNoItem", "\tErr%d", test_exm->numExamples, "\tAvg\n");
				break;
		  default: break;		
		}
}

void freeResF(char **weightF, FILE **f1, char **outF, FILE **f2, char **itemacuTrF, FILE **f3, char **itemacuTeF,  FILE **f4, char **trainfreqF, 
	FILE **f5, char **outPhonTrF, FILE **f6, char **outPhonTeF, FILE **f7, char **outPhonTrVecF, FILE **f8, char **outPhonTeVecF, FILE **f9, char **outPhonErrTrF, FILE **f10, char **outPhonErrTeF)
{ // free result file names and files;
	// record connection weights of the network;
	free(*weightF); *weightF=NULL;	
	// record training error, training accuracy and testing accuracy;
	free(*outF); *outF=NULL; *f1=NULL;	
	// record item-based training and testing accuracy;
	free(*itemacuTrF); *itemacuTrF=NULL; *f2=NULL; free(*itemacuTeF); *itemacuTeF=NULL; *f3=NULL;	
	// record accumulative occurring frequency of training examples during training;
	free(*trainfreqF); *trainfreqF=NULL; *f4=NULL;
	// record output phonemes of training and testing examples;
	free(*outPhonTrF); *outPhonTrF=NULL; *f5=NULL; free(*outPhonTeF); *outPhonTeF=NULL; *f6=NULL;	
	// record output vectors of training and testing examples;
	if(_recVec==1) { free(*outPhonTrVecF); *outPhonTrVecF=NULL; *f7=NULL; free(*outPhonTeVecF); *outPhonTeVecF=NULL; *f8=NULL; }
	// record output errors of phonemes;
	free(*outPhonErrTrF); *outPhonErrTrF=NULL; *f9=NULL; free(*outPhonErrTeF); *outPhonErrTeF=NULL; *f10=NULL;
}

void setupDirect(char **subDirect, int iseq)
{ // set up subDirect and root, and create subDirect in the folder;
	// set up subDirect;
	char sep[_FileLen];
	sprintf(sep, "%d", iseq);
	(*subDirect)=malloc((strlen("./")+2+(int)(log10((double)(iseq))+1)+1)*sizeof(char)); assert((*subDirect)!=NULL);
	strcpy(*subDirect, "./"); strcat(*subDirect, sep); strcat(*subDirect, "/");
	// based on _runmode, create subDirect;
	if((_runmode==0)||(_runmode==1)||(_runmode==3))
		{ if(mkdir(*subDirect, ACCESSPERMS)==-1) { printf("can't create directory %s!\n", *subDirect); exit(1); } // used in Linux;
		}
}

void storeSeed(char *subDirect)
{ // store seed to seed.txt;
	FILE *f=NULL;
	char *fName=NULL, *seedDirect=NULL;
	if(_runmode==0) { fName=malloc((strlen("seed_OtoP.txt")+1)*sizeof(char)); assert(fName!=NULL); strcpy(fName, "seed_OtoP.txt"); }
	else if(_runmode==1) { fName=malloc((strlen("seed_PtoP.txt")+1)*sizeof(char)); assert(fName!=NULL); strcpy(fName, "seed_PtoP.txt");	}
	else { fName=malloc((strlen("seed_PtoP_OtoP.txt")+1)*sizeof(char)); assert(fName!=NULL); strcpy(fName, "seed_PtoP_OtoP.txt"); }
	seedDirect=malloc((strlen(subDirect)+strlen(fName)+1)*sizeof(char)); assert(seedDirect!=NULL);
	strcpy(seedDirect, subDirect); strcat(seedDirect, fName);
	if((f=fopen(seedDirect,"w"))==NULL) { printf("Can't create %s\n", seedDirect); exit(1); } 
	fprintf(f, "Seed=%u\n", _seed); fclose(f);	// store seed into seed.txt;
	printf("Seed = %u\n", _seed);	// print out the seed used;
	free(fName); fName=NULL; free(seedDirect); seedDirect=NULL;	// free fName and seedDirect;
}

// main function;
void main(int argc,char *argv[])
{ // main function: initialize network, and train, and calculate parameters;
  	int i, iseq;
	unsigned int run;
	char *subDirect=NULL;
	char *weightF=NULL;
	FILE *f1=NULL, *f2=NULL, *f3=NULL, *f4=NULL, *f5=NULL, *f6=NULL, *f7=NULL, *f8=NULL, *f9=NULL, *f10=NULL;
	char *outF=NULL, *itemacuTrF=NULL, *itemacuTeF=NULL, *trainfreqF=NULL, 
		*outPhonTrF=NULL, *outPhonTeF=NULL, *outPhonTrVecF=NULL, *outPhonTeVecF=NULL, *outPhonErrTrF=NULL, *outPhonErrTeF=NULL;

	readpara();	// reading network parameters and parameters for running;
	readarg(argc, argv); // read runtime parameters from command line input;

	printf("input subdic name(int): "); scanf("%d", &iseq); printf("subdic is %d\n", iseq);
	setupDirect(&subDirect, iseq);	// setup subDirect and root, and create directories;

	if(_seed==0) _seed=(long)(time(NULL))+100*iseq; // if the input seed is 0, meaning randomly setting the seed;
	storeSeed(subDirect);	// store seed to seed.txt and print seed;

	announce_version(); setbuf(stdout, NULL); 
	mikenet_set_seed(_seed);	// set up seed for mikenet
	load_phoneme(_phoF);	// initialize phonemes;

	switch(_runmode)
		{ case 0: case 2: case 3: case 4: 
				// scratch OtoP training (_runmode==0 or _runmode==3); OtoP training by loading weights from PtoP training network (_runmode==2 or _runmode==4);
		  	 	// 1) build network;
		  	 	printf("Build OtoP network:\n"); 
		  		build_model(_tick_OtoP); printf("No. Conns: %d\n", count_connections(reading));  // calculate number of connections and print out;
		  		if((_runmode==2)||(_runmode==4))
					{ // load weights from previously trained PtoP network;
		  	  		  crtFName(&weightF, subDirect, "weights_ptop.txt");
			  		  load_weights(reading, weightF); //another option: load_binary_weights(reading, weightF);
			  		  free(weightF); weightF=NULL;
					}	  

				// 2) load training and testing examples;
		  		train_exm=load_examples(_exTrF, _tick_OtoP); test_exm=load_examples(_exTeF, _tick_OtoP);
		  		if((_runmode==3)||(_runmode==4)) 
		  			{ // also load training and testing examples for interleave PtoP training; note that in this situation, _tick_PtoP = _tick_OtoP;
					  train_PtoP_exm=load_examples(_exTrF_PtoP, _tick_PtoP); test_PtoP_exm=load_examples(_exTeF_PtoP, _tick_PtoP);
					}
				break;
		  case 1: 
				// scratch PtoP training;
		  		// 1) build network;	
		  		printf("Build PtoP network:\n"); 
		  		build_model(_tick_PtoP); printf("No. Conns: %d\n", count_connections(reading));  // calculate number of connections and print out;

		  		// 2) load training and testing examples;
		  		train_PtoP_exm=load_examples(_exTrF_PtoP, _tick_PtoP); test_PtoP_exm=load_examples(_exTeF_PtoP, _tick_PtoP);
				break;
		  default: break;		
		}
	
	// 3) crete result file names and file headers;
	setResF(subDirect, &weightF, &f1, &outF, &f2, &itemacuTrF, &f3, &itemacuTeF, &f4, &trainfreqF, 
			&f5, &outPhonTrF, &f6, &outPhonTeF, &f7, &outPhonTrVecF, &f8, &outPhonTeVecF, &f9, &outPhonErrTrF, &f10, &outPhonErrTeF);
	
	// 4) train the network;
	switch(_runmode)
		{ case 0: case 2: case 3: case 4:
				if((_runmode==0)||(_runmode==2)) printf("Start OtoP training!\n");
		  		else if((_runmode==3)||(_runmode==4)) printf("Start OtoP (interleave with PtoP) training!\n");
		  		train(reading, f1, outF, f2, itemacuTrF, f3, itemacuTeF, f4, trainfreqF, 
					  f5, outPhonTrF, f6, outPhonTeF, f7, outPhonTrVecF, f8, outPhonTeVecF, f9, outPhonErrTrF, f10, outPhonErrTeF);
		  		printf("Done OtoP training!\n");
				break;
		  case 1:
				printf("Start PtoP training!\n");
		  		train(reading, f1, outF, f2, itemacuTrF, f3, itemacuTeF, f4, trainfreqF, 
					  f5, outPhonTrF, f6, outPhonTeF, f7, outPhonTrVecF, f8, outPhonTeVecF, f9, outPhonErrTrF, f10, outPhonErrTeF);
		  		printf("Done PtoP training!\n");  
		  		break;
		  default: break;		
		}

	// 5) save network weights;
	save_weights(reading, weightF);	//another option: save_binary_weights(reading, weightF);
				
	// 6) free result file names and file pointers;
	freeResF(&weightF, &f1, &outF, &f2, &itemacuTrF, &f3, &itemacuTeF, &f4, &trainfreqF, 
			 &f5, &outPhonTrF, &f6, &outPhonTeF, &f7, &outPhonTrVecF, &f8, &outPhonTeVecF, &f9, &outPhonErrTrF, &f10, &outPhonErrTeF);
					
	// 7) free train_exm and test_exm; 
	switch(_runmode)
		{ case 0: case 2: free(train_exm); train_exm=NULL; free(test_exm); test_exm=NULL; break;	// scracth OtoP training;
		  case 1: free(train_PtoP_exm); train_PtoP_exm=NULL; free(test_PtoP_exm); test_PtoP_exm=NULL; break;	// scracth PtoP training;
		  case 3: case 4:	// interleave OtoP PtoP training;
		  		free(train_exm); train_exm=NULL; free(test_exm); test_exm=NULL; 
				free(train_PtoP_exm); train_PtoP_exm=NULL; free(test_PtoP_exm); test_PtoP_exm=NULL; 
				break;
		  default: break;
		}
	// 8) free network and phon dictionary
	free_net(reading); reading=NULL;
	delete_phoneme();	// empty _phon;
	
	free(subDirect); subDirect=NULL;	// free subDirect;	
}

