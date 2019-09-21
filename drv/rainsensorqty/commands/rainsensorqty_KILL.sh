#!/bin/bash
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "rainsensorqty_KILL.sh"
# script for killing monitor process(es)
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
		echo "process $pid pid and its child(ren)"
		children_pid="$(ps -ef| awk "\$3==$pid {print \$2}")"
		ps -fp $pid
		ps -fp $children_pid | tail +2
		echo -e "\nsending TERM signal to $pid and its child(ren)"
		echo kill $children_pid
		echo kill $pid
		kill $children_pid
		kill $pid
		echo -e "\nchecking $pid pid and its child(ren) are still alive"
		for process in $pid $children_pid
		do
        		if ps -fp $process >/dev/null ; then
				echo "$process is still alive"
			else
				echo "$process is dead"
			fi
		done
	else
		echo "no RAIN process alive"
        fi
else
	echo "no RAIN process alive"
fi

