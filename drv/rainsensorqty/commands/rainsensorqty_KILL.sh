#!/bin/bash

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

fi

