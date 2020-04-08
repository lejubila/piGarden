#!/bin/bash
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "test_rainsensorqty_CHECK.sh"
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

# two variables for store rain data
# RAINSENSORQTY_LASTRAIN
# RAINSENSORQTY_HISTORY

echo "RAIN HISTORY - last two events"
tail -2 $RAINSENSORQTY_HISTORY 
tail -2 $RAINSENSORQTY_HISTORY | rain_when_amount

echo "...removing last event"
removelastrain
echo "...rebuilding ${RAINSENSORQTY_HISTORY} from ${RAINSENSORQTY_HISTORYRAW}"
if ! rainevents > ${RAINSENSORQTY_HISTORY} ; then
	echo "WARNING: rainevents function had error"
fi
tail -1 ${RAINSENSORQTY_HISTORYRAW} > ${RAINSENSORQTY_LASTRAIN}

echo -e "\nnew RAIN HISTORY - last two events"
tail -2 $RAINSENSORQTY_HISTORY 
tail -2 $RAINSENSORQTY_HISTORY | rain_when_amount

