#!/bin/bash
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "rainsensorqty_RESET.sh"
# script for reset counter in monitor script
# Version: 0.2.0a
# Data: 29/Aug/2019

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

# check if rain monitor process is running...
if [[ -f "$RAINSENSORQTY_MONPID" ]] ; then
        pid="$( < "$RAINSENSORQTY_MONPID" )"
        if ps -fp $pid >/dev/null ; then
		echo "sending SIGUSR1 to $pid"
		kill -SIGUSR1 $pid
		echo -e "sent SIGUSR1 - reset will be shown after next cycle"
	else
		echo "no RAIN process alive"
        fi
else
	echo "no RAIN process alive"
fi
