#!/bin/bash
#
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "drv_rainsensorqty_monitor.sh"
# monitor script
# Version: 0.2.0
# Data: 11/Aug/2019

###############
#    MAIN     #
###############

DIRNAME="$( dirname $0 )"
f="$(basename $0)"
. $DIRNAME/common.include.sh
set_var="$DIRNAME/.set_var"

if [[ -f "$set_var" ]] ; then
	en_echo "NORMAL: file $set_var found - getting variables"
	. "$set_var"
else
	echo "ERROR: $set_var not found"
	exit 1
fi

#drvt="$( echo $RAIN_GPIO | $CUT -f 1 -d: )"
#drv="$( echo $RAIN_GPIO | $CUT -f 2 -d: )"
gpio_port="$( echo $RAIN_GPIO | $CUT -f 3 -d: )"

# check if no other rain monitor process running...
if [[ -f "$RAINSENSORQTY_MONPID" ]] ; then
	pid="$( < "$RAINSENSORQTY_MONPID" )"
	if ps -fp $pid >/dev/null ; then
		drv_rainsensorqty_writelog $f "ERROR monitor process already running\n$( ps -fp $pid )"
		exit 1
	fi
fi

echo $$ > $RAINSENSORQTY_MONPID
drv_rainsensorqty_writelog $f "NORMAL - $$ pid monitor process started - see $RAINSENSORQTY_MONPID"

# init variables
MMEACH="$RAINSENSORQTY_MMEACH"
(( counter=0 ))
rain_history

echo ""
en_echo "---- NEW RUN "

# loop forever
while true
do
	before=`date +%s`
	sleep $RAINSENSOR_ANTIBOUNCE
	en_echo "WAITING FOR PULSE" 
	$GPIO -g wfi $gpio_port $RAINSENSORQTY_PULSE
	now=`date +%s`
	(( elapsed = now - before ))
	if (( elapsed >= RAINSENSORQTY_SECSBETWEENRAINEVENT )) ; then
		(( counter=0 ))
		drv_rainsensorqty_writelog $f "first drops after $elapsed seconds since last rain ( greater than $RAINSENSORQTY_SECSBETWEENRAINEVENT )- new cycle - waiting for $( $JQ -n "$RAINSENSORQTY_LOOPSFORSETRAINING * $MMEACH" )" &
		rain_history
	fi
  	(( counter+=1 ))
	en_echo "PULSE RECEIVED (counter $counter)" 
	MMWATER=$( $JQ -n "$counter*$MMEACH" )
	text=$(printf "%.2f mm height (loop %d)" $MMWATER $counter )
	if (( counter >= RAINSENSORQTY_LOOPSFORSETRAINING )) ; then 
		drv_rainsensorqty_writelog $f "RAINING - $text" &
		echo "$(date +%s):$counter" > ${RAINSENSORQTY_LASTRAIN} 
	else
		drv_rainsensorqty_writelog $f "now is $text" &
	fi
done
