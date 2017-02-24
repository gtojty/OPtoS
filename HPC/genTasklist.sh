#!/bin/bash
if [ "$#" -lt 4 ]; then
	echo "At least four arguments (NUMRUN, WORKDIREC, MODE1 and LOG1) are required!"
	exit 1
fi
if [ "$#" -gt 6 ]; then
	echo "Too many arguments!"
	exit 1
fi

i=1;
while [ $i -le $1 ] 
do 
  if [ "$#" -eq 4 ]; then
  	echo "cd" $2 "; ./msf.sh" $i $3 $4 >> tasklist$4.txt
  elif [ "$#" -eq 6 ]; then
  	echo "cd" $2 "; ./msf.sh" $i $3 $4 "; ./msf.sh" $i $5 $6 >> tasklist$4$6.txt
  fi
  i=$((i+1))
done
