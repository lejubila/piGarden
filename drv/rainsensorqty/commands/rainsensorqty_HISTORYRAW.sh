#!/bin/bash
#
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "rainsensorqty_CHECK.sh"
# test script for checking rain status using drv_rainsensorqty_rain_sensor_get function
# Version: 0.2.5
# Data: 07/Apr/2020

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


if [[ $# = 0 ]] ; then
	cmd=cat
	echo "processing all entire  $RAINSENSORQTY_HISTORYRAW file, will go on? (y/n)"
	read answer
	echo $answer
	[[ $answer = [yY] ]] || exit 1
else
	if (( $1 >= 1 )) ; then
		echo "processing $1 lines of $RAINSENSORQTY_HISTORYRAW file"
		cmd="tail -$1"
	else
		echo "argument not recognized - exit"
		exit 1
	fi
fi
echo -e "\n\n"

$cmd $RAINSENSORQTY_HISTORYRAW | while read line
do
	set -- ${line//:/ }
	secs=$1
	counter=$2
	echo "$(sec2date $1):$counter"
done
 
