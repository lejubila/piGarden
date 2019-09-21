#!/bin/bash
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "test_rainsensorqty_CHECK.sh"
# test script for checking rain status using drv_rainsensorqty_rain_sensor_get function
# Version: 0.2.0a
# Data: 13/Aug/2019

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

rain_history # update rain history file if not

echo "RAIN HISTORY - last five events"
tail -5 $RAINSENSORQTY_HISTORY | rain_when_amount

echo -e "\nLAST RAIN"
cat $RAINSENSORQTY_LASTRAIN | rain_when_amount

#exit # for test

echo -e "\nbackup to .old files"
cp -p $RAINSENSORQTY_HISTORY ${RAINSENSORQTY_HISTORY}.old
cp -p  $RAINSENSORQTY_LASTRAIN ${RAINSENSORQTY_LASTRAIN}.old

echo "...removing last event"
head -n-1 ${RAINSENSORQTY_HISTORY}.old > $RAINSENSORQTY_HISTORY 
tail -1 $RAINSENSORQTY_HISTORY > $RAINSENSORQTY_LASTRAIN 

echo -e "\nnew RAIN HISTORY - last five events"
tail -5 $RAINSENSORQTY_HISTORY | rain_when_amount

echo -e "\nnew LAST RAIN"
cat $RAINSENSORQTY_LASTRAIN | rain_when_amount
