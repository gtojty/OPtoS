#!/bin/bash
if [ "$#" -lt 3 ]; then
	echo "At least three arguments are required!"
	exit 1
fi
if [ "$#" -gt 9 ]; then
	echo "Too many arguments!"
	exit 1
fi

i=1;
while [ $i -le $1 ] 
do
  echo "run: " $i
  if [ "$#" -eq 3 ]; then
  	echo $i | time ./OtoS -runmode $2 > $i$3.log
  elif [ "$#" -eq 4 ]; then
  	echo $i | time ./OtoS -runmode $2 -iter $4 > $i$3.log
  elif [ "$#" -eq 5 ]; then
  	echo $i | time ./OtoS -runmode $2 -iter $4 -rep $5 > $i$3.log
  elif [ "$#" -eq 6 ]; then
  	echo $i | time ./OtoS -runmode $2 -iter $4 -rep $5 -iter_stos $6 > $i$3.log
  elif [ "$#" -eq 7 ]; then
  	echo $i | time ./OtoS -runmode $2 -iter $4 -rep $5 -iter_stos $6 -rep_stos $7 > $i$3.log	 
  elif [ "$#" -eq 8 ]; then
  	echo $i | time ./OtoS -runmode $2 -iter $4 -rep $5 -iter_stos $6 -rep_stos $7 -samp $8 > $i$3.log
  else
  	echo $i | time ./OtoS -runmode $2 -iter $4 -rep $5 -iter_stos $6 -rep_stos $7 -samp $8 -vthres $9 > $i$3.log
  fi
  i=$((i+1))
done
