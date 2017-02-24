# Document Install Mikenet-v8.0 in linux machine

## Steps
1. Download *.tar.gz file from http://www.cnbc.cmu.edu/~mharm/research/tools/mikenet/.
2. unzip:
   ```
   gunzip mikenet_v8.targ.gz
   tar xvf mikenet_v8.tar
   ```
3. set up environment file:
   in shrc shell: `open/create .cshrc file`, and put: 
	    `setenv MIKENET_DIR ${HOME}/Mikenet-v8.0`
	 in bash shell: `open/create .bashrc file`, and put:
	  	```
	  	MIKENET_DIR=${HOME}/Mikenet-v8.0
		  export MIKENET_DIR
		  ```
	 check whether the environment is set: ${HOME}   
4. Make file:
	    ```
	    cd Mikenet-v8.0/src 
	    make clean 
	    make cc
	    ```
5. Run an example: 
	    ```
	    cd Mikenet-v8.0/demos/xor
	    rm xor
	    make xor
	    ./xor
	    ```
	 Go to ~/mikenet/demos/tutorial and look at the code in the tutorial.c file
6. To build your own simulation, start with one of the existing demos (like xor), and copy all of the files into your own directory. Change xor.c and xor.ex as you see fit, and then do a "make" to build your simulation. You don't need to recompile the libraries, just your own simulation .c file(s) when you change things.
7. How to use different functions and examples: http://cnbc.cmu.edu/~mharm/research/tools/mikenet/	

To run an example of MikeNet:
Makefile format: (based on examples of benchmark)

```
#to use gcc, use these settings 
CC = ${MYCC}
DEBUG = ${MYDEBUG}
LINK_ARGS= 
####SPECIAL= -funroll-loops
SPECIAL=

### note: if mikenet is installed at the system level,
### (like, /usr/local/include, /usr/local/lib) then you don't need
### this gunk.  

LIBHOME=${MIKENET_DIR}/lib/${ARCH}/
INCLUDEHOME=${MIKENET_DIR}/include

all:	OtoP 

OtoP:	OtoP.c model.c Makefile
  gcc -o OtoP OtoP.c model.c \${DEBUG} -I${INCLUDEHOME} ${LIBHOME}/libmikenet.a -lm

clean:
  rm -f *.o OtoP
```
Some Notes:
  * CC, DEBUG, LINK_ARGS, SPECIAL: define the commands for compiling using gcc
  * LIBHOME and INCLUDEHOME: define the lib of Mikenet
  * all:  followed up exe file names
  * for each exe file, write the command to compile
  * clean: rm -f remove .o and exe files generated

to compile, use:  `make -f Makefile`

to clean, use:  `make -f Makefile clean`