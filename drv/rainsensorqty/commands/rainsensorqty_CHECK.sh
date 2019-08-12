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

# restituisce 0 se piove, e nell'output di testo il valore di "$RAIN_GPIO_STATE"
# restituisce 99 se non piove, output "norain"
# esce con 1 se non c'e' il monitoring, output "ERROR"

drv_rainsensorqty_rain_sensor_get
case $? in
	0)  echo "NORMAL: it's raining" ;;
	99) echo "NORMAL: it's not raining" ;;
	1)  echo "ERROR: monitor process $DIR_SCRIPT/drv/rainsensorqty/drv_rainsensorqty_monitor.sh is not running" ;;
esac

