#define _LineLen 3000
#define _nameLen 10

// network components
Net *reading;
Group *input, *hidden, *output, *semhid;
Connections *c1, *c2, *c3, *c4, *c5;
ExampleSet *train_exm, *test_exm, *train_StoS_exm, *test_StoS_exm;

// network parameters
int _SimType;
int _tick_StoS;
int _tick_OPtoS;
double _intconst;
int _tai;
double _epsi;
int _acttype,_errortype;
int _weightnoisetype; 
double _weightnoise,_actnoise,_inputnoise;
double _errrad,_range;
int _OrthoPhonS,_HidS,_SemS,_SemHidS;

// parameters for semantics
int _sem_number;
typedef struct
{ char name[_nameLen];	// name of semantics;
  Real *vec;	// features of semantics;
} Sem;
Sem *_sem;

// parameters for file names storing semantics and training and testing examples;
char *_semF;
char *_exTrF_StoS, *_exTeF_StoS;
char *_exTrF, *_exTeF;

// function to build the network and phoneme dictionary;
void build_model(int ticks);
int count_connections(Net *net);
void load_sem(char *SemF);
void delete_sem(void);
