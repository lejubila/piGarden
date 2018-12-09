#!/bin/bash
DIR_SCRIPT=/home/pi/piGarden
NAME_SCRIPT="not_needed"
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

drv_rainsensorqty_rain_sensor_get
echo "drv_rainsensorqty_rain_sensor_get $?"
