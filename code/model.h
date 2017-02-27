#define _LineLen 300

// network components
Net *reading;
Group *input, *hidden, *output, *semhid;
Connections *c1, *c2, *c3, *c4, *c5;
ExampleSet *train_exm, *test_exm, *train_StoS_exm, *test_StoS_exm;

// network parameters
int _tick_StoS;
int _tick_OtoS;
double _intconst;
int _tai;
double _epsi;
int _acttype,_errortype;
int _weightnoisetype; 
double _weightnoise,_actnoise,_inputnoise;
double _errrad,_range;
int _OrthoS,_HidS,_SemS,_SemHidS;

// parameters for file names storing training and testing examples;
char *_semF;
char *_exTrF_StoS, *_exTeF_StoS;
char *_exTrF, *_exTeF;

// function to build the network and phoneme dictionary;
void build_model(int ticks);
int count_connections(Net *net);
