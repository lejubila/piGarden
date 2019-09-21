#!/bin/bash
#
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "rainsensorqty_CHECK.sh"
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

rain_history # update rain history file if not

echo "RAIN HISTORY"
cat $RAINSENSORQTY_HISTORY | rain_when_amount
