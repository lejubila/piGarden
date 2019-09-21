#!/bin/bash
#
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "drv_rainsensorqty_monitor.sh"
# monitor script
# Version: 0.2.2
# Data: 08/Sep/2019

resetcounter()
{
        (( counter = 0 ))
        drv_rainsensorqty_writelog $f "SIGUSR1 received after last PULSE - counter resetted" & 
        echo "SIGUSR1 received after last PULSE - counter resetted"
}

###############
#    MAIN     #
###############

trap "resetcounter" SIGUSR1


DIRNAME="$( dirname $0 )"
f="$(basename $0)"
. $DIRNAME/common.include.sh

RAINSENSORQTY_VAR=$TMPDIR/.rainsensorqty_var

if [[ -f "$RAINSENSORQTY_VAR" ]] ; then
	en_echo "NORMAL: file $RAINSENSORQTY_VAR found - getting variables"
	. "$RAINSENSORQTY_VAR"
else
	echo "ERROR: $RAINSENSORQTY_VAR not found"
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
en_echo "---- NEW RUN ----"

# loop forever
while true
do
	before=`date +%s`
	sleep $RAINSENSOR_DEBOUNCE
	en_echo "WAITING FOR $RAINSENSORQTY_PULSE PULSE" 
	$GPIO -g wfi $gpio_port $RAINSENSORQTY_PULSE
	now=`date +%s`
	(( elapsed = now - before ))
	if (( elapsed >= RAINSENSORQTY_SECSBETWEENRAINEVENT )) ; then
		(( counter=0 ))
		drv_rainsensorqty_writelog $f "first drops after $elapsed seconds since last rain ( greater than $RAINSENSORQTY_SECSBETWEENRAINEVENT )- new cycle - waiting for $( $JQ -n "$RAINSENSORQTY_LOOPSFORSETRAINING * $MMEACH" ) mm of rain" &
		en_echo "---- NEW CYCLE ----"
		rain_history &
	fi
  	(( counter+=1 ))
	en_echo "$RAINSENSORQTY_PULSE PULSE #$counter RECEIVED" 
	echo "$now:$counter" > ${RAINSENSORQTY_STATE} &
	echo "$now:$counter" >> ${RAINSENSORQTY_STATE_HIST} &
	MMWATER=$( $JQ -n "$counter*$MMEACH" )
	text=$(printf "%.2f mm height (#%d pulse)" $MMWATER $counter )
	if (( counter >= RAINSENSORQTY_LOOPSFORSETRAINING )) ; then 
		drv_rainsensorqty_writelog $f "RAINING - $text" &
		echo "$now:$counter" > ${RAINSENSORQTY_LASTRAIN} 
	else
		drv_rainsensorqty_writelog $f "now is $text" &
	fi
done
