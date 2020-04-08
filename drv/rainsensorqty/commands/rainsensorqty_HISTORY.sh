#!/bin/bash
#
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "rainsensorqty_CHECK.sh"
# test script for checking rain status using drv_rainsensorqty_rain_sensor_get function
# Version: 0.2.5
# Data: 08/Jan/2020

SCRIPTDIR="$(cd `dirname $0` ; pwd )"
SCRIPTNAME=${0##*/}
cd $SCRIPTDIR/.. # command is a subdirectory of driver

DIR_SCRIPT=/home/pi/piGarden # home directory of piGarden
CONFIG_ETC="/etc/piGarden.conf"
LOG_OUTPUT_DRV_FILE="$DIR_SCRIPT/log/$LOG_OUTPUT_DRV_FILE"

. $CONFIG_ETC

. ./common.include.sh
. ./config.include.sh 
. ./init.include.sh
. ./rainsensor.include.sh

if [[ $1 = "-force" ]] ; then
	if [[ -s $RAINSENSORQTY_HISTORY ]] ; then
		echo backup $RAINSENSORQTY_HISTORY to ${RAINSENSORQTY_HISTORY}.old$$
		cp $RAINSENSORQTY_HISTORY ${RAINSENSORQTY_HISTORY}.old$$
	fi

	echo "generate all rain events to $RAINSENSORQTY_HISTORY"
	if ! rainevents > ${RAINSENSORQTY_HISTORY} ; then
		echo "WARNING: rainevents function had error"
	fi
	shift
fi

if ! rain_history tmp ; then # update rain history with last rain if not
	echo "WARNING: rain_history function had error"
fi

cmd="cat"
if [[ $# > 0 ]] ; then
	if (( $1 >= 1 )) ; then
		echo "processing last $1 lines of $RAINSENSORQTY_HISTORYRAW file"
		cmd="tail -$1"
	else
		echo "argument not recognized - exit"
		exit 1
	fi
fi
echo -e "\n\n"

if [[ -s $RAINSENSORQTY_HISTORY ]] ; then
	echo "RAIN HISTORY"
	cat $RAINSENSORQTY_HISTORY $RAINSENSORQTY_HISTORYTMP | $cmd | rain_when_amount
else
	echo "WARNING: no \$RAINSENSORQTY_HISTORY file"
fi
