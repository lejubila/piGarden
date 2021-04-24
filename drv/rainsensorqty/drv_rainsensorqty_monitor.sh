#!/bin/bash
#
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "drv_rainsensorqty_monitor.sh"
# monitor script
# Version: 0.2.5c
# Data: 08/Dec/2020

resetcounter()
{
        (( counter = 0 ))
        drv_rainsensorqty_writelog $f "SIGUSR1 received after last PULSE - counter resetted" & 
        echo "SIGUSR1 received after last PULSE - counter resetted"
}

# DEBUG FUNCTION:
testloop()
{
	touch /tmp/tick
	while true
	do
		if [[ $( < /tmp/tick ) = "1" ]] ; then
			break
		fi
		sleep 1
	done
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

echo ""
en_echo "---- NEW RUN ----"

# check if monitor script was killed before writing a complete rain event
check_incomplete_loop 
case $? in 
	2) echo "\$RAINSENSORQTY_HISTORY - wrong entry found - no fix possible" ;;
	1) echo "\$RAINSENSORQTY_HISTORY - fixed incomplete loop" ;;
	0) echo "\$RAINSENSORQTY_HISTORY - no incomplete loop needed to be fixed" ;;
esac

# init variables
MMEACH="$RAINSENSORQTY_MMEACH"
(( counter=0 ))
before="-1"

en_echo "WAITING FOR $RAINSENSORQTY_PULSE PULSE" 

# loop forever
while true
do
	sleep $RAINSENSOR_DEBOUNCE
	#DEBUG: testloop #DEBUG
	$GPIO -g wfi $gpio_port $RAINSENSORQTY_PULSE
	now=`date +%s`
	(( elapsed = now - before ))
	if (( elapsed >= RAINSENSORQTY_SECSBETWEENRAINEVENT )) ; then
		last_event="$started:$before:$counter"
		(( counter=0 ))
		drv_rainsensorqty_writelog $f "first drops after $elapsed seconds since last rain ( greater than $RAINSENSORQTY_SECSBETWEENRAINEVENT )- new cycle - waiting for $( $JQ -n "$RAINSENSORQTY_LOOPSFORSETRAINING * $MMEACH" ) mm of rain" &
		(( before > 0 )) && echo $last_event >> $RAINSENSORQTY_HISTORY
		en_echo "---- NEW CYCLE ----"
	fi
  	(( counter+=1 ))
  	(( counter == 1 )) && (( started = now ))
	echo "$now:$counter" >> ${RAINSENSORQTY_HISTORYRAW} &
	MMWATER=$( $JQ -n "$counter*$MMEACH" )
	en_echo $( printf "%s PULSE #%d RECEIVED (%.2f mm)" $RAINSENSORQTY_PULSE $counter $MMWATER )
	text=$(printf "%.2f mm height (#%d pulse)" $MMWATER $counter )
	if (( counter >= RAINSENSORQTY_LOOPSFORSETRAINING )) ; then 
		drv_rainsensorqty_writelog $f "RAINING - $text" &
		echo "$now:$counter" > ${RAINSENSORQTY_LASTRAIN} 
	else
		drv_rainsensorqty_writelog $f "now is $text" &
	fi
	(( before = now ))
done
