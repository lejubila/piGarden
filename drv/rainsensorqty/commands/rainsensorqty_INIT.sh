#!/bin/bash
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "rainsensorqty_INIT.sh"
# test script for initialize driver and executing monitor process
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

. $CONFIG_ETC

. ./config.include.sh
. ./common.include.sh
. ./init.include.sh
. ./rainsensor.include.sh

drv_rainsensorqty_rain_sensor_init

drv_rainsensorqty_init
