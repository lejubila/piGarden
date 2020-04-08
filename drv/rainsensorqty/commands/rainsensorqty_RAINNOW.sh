#!/bin/bash
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "rainsensorqty_RAINNOW.sh"
# test script for simulate rain ... now!
# Version: 0.2.5
# Data: 07/Apr/2020

SCRIPTDIR="$(cd `dirname $0` ; pwd )"
SCRIPTNAME=${0##*/}
cd $SCRIPTDIR/.. # command is a subdirectory of driver

DIR_SCRIPT=/home/pi/piGarden # home directory of piGarden
CONFIG_ETC="/etc/piGarden.conf"
. $CONFIG_ETC

. ./config.include.sh
. ./common.include.sh
. ./init.include.sh
. ./rainsensor.include.sh

wait=0
timestart=$( date +%s)
if [[ $# -ne 0 ]] ; then
	if [[ $# = 1 ]] ; then 
		howmany=$1
		echo "one argument passed: rain event for $howmany loops"
		(( time = timestart - howmany ))
	elif [[ $# = 2 ]] ; then 
		howmany=$1
		wait=$2
		echo "two arguments passed: rain event for $howmany loops every $wait seconds"
		(( time = timestart ))
	else
		echo "too many arguments... exit"
		exit 1
	fi
else
	howmany=$RAINSENSORQTY_LOOPSFORSETRAINING
	(( time = timestart - $RAINSENSORQTY_LOOPSFORSETRAINING ))
fi


echo "RAIN now! (for $howmany loops)"
for (( c=1; c<=$howmany; c++ )) 
do
	if (( wait > 0 )) ; then	
		time=$( date +%s)
	else
		(( time+= 1 ))
	fi
	linetoadd="$time:$c"
	echo $linetoadd >> $RAINSENSORQTY_HISTORYRAW
	sleep $wait
	echo -e ".\c"
done
echo

if ! rain_history ; then # update rain history with last rain if not
	echo "WARNING: rain_history function had error"
fi

echo $linetoadd > ${RAINSENSORQTY_LASTRAIN}
echo "file ${RAINSENSORQTY_LASTRAIN} updated."

echo "last 2 rain events:"
tail -2 $RAINSENSORQTY_HISTORY | rain_when_amount
