#!/bin/bash
#
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "test_rainsensorqty_CHECK.sh"
# test script for checking rain status using drv_rainsensorqty_rain_sensor_get function
# Version: 0.2.0
# Data: 11/Aug/2019

SCRIPTDIR="$(cd `dirname $0` ; pwd )"
SCRIPTNAME=${0##*/}
cd $SCRIPTDIR/.. # command is a subdirectory of driver

DIR_SCRIPT=/home/pi/piGarden # home directory of piGarden
CONFIG_ETC="/etc/piGarden.conf"
TMP_PATH="/run/shm"
if [ ! -d "$TMP_PATH" ]; then
        TMP_PATH="/tmp"
fi

LOG_OUTPUT_DRV_FILE="$DIR_SCRIPT/log/$LOG_OUTPUT_DRV_FILE"

. $CONFIG_ETC

. ./common.include.sh
. ./config.include.sh
. ./init.include.sh
. ./rainsensor.include.sh

echo "RAIN HISTORY"
rain_history

cat $RAINSENSORQTY_HISTORY | while read line
do
	set -- ${line//:/ }
	when=$1
	howmuch=$2
	printf "RAINED on %s for %.2f mm\n" "$(date --date="@$1")" $( $JQ -n "$howmuch * $RAINSENSORQTY_MMEACH" )
done

