#!/bin/bash
if [ "$#" -lt 3 ]; then
	echo "At least two arguments are required!"
	exit 1
fi
if [ "$#" -gt 9 ]; then
	echo "Too many arguments!"
	exit 1
fi

if [ "$#" -eq 3 ]; then
 	echo $1 | time ./OtoS -runmode $2 > $1$3.log
elif [ "$#" -eq 4 ]; then
 	echo $1 | time ./OtoS -runmode $2 -iter $4 > $1$3.log
elif [ "$#" -eq 5 ]; then
 	echo $1 | time ./OtoS -runmode $2 -iter $4 -rep $5 > $1$3.log
elif [ "$#" -eq 6 ]; then
 	echo $1 | time ./OtoS -runmode $2 -iter $4 -rep $5 -iter_stos $6 > $1$3.log
elif [ "$#" -eq 7 ]; then
 	echo $1 | time ./OtoS -runmode $2 -iter $4 -rep $5 -iter_stos $6 -rep_stos $7 > $1$3.log
elif [ "$#" -eq 8 ]; then
	echo $1 | time ./OtoS -runmode $2 -iter $4 -rep $5 -iter_stos $6 -rep_stos $7 -samp $8 > $1$3.log 	
else
 	echo $1 | time ./OtoS -runmode $2 -iter $4 -rep $5 -iter_stos $6 -rep_stos $7 -samp $8 -vthres $9 > $1$3.log
fi