#!/bin/bash
#
# Bash monitor script to measure rainfall
# Author: androtto
#
#


###############
#    MAIN     #
###############


DIRNAME="$( dirname $0 )"
f="$(basename $0)"
. $DIRNAME/common.include.sh

echo "$(date) ---------------- NEW RUN "

if [[ -f "$DIRNAME/set_var" ]] ; then
	echo "NORMAL: file $DIRNAME/set_var found - getting variables"
	. "$DIRNAME/set_var"
else
	echo "ERROR: $DIRNAME/set_var not found"
	exit 1
fi

#drvt="$( echo $RAIN_GPIO | $CUT -f 1 -d: )"
#drv="$( echo $RAIN_GPIO | $CUT -f 2 -d: )"
gpio_port="$( echo $RAIN_GPIO | $CUT -f 3 -d: )"

#got from config file above:
#RAINSENSORQTY_LASTRAIN="$STATUS_DIR/rainsensorqty_lastrain"
#RAINSENSORQTY_LOG="$DIR_SCRIPT/log/rainsensorqty.log"
#RAINSENSORQTY_MONPID="$TMP_PATH/rainsensorqty_monitor.pid"
#RAINSENSORQTY_DIR="$DIR_SCRIPT/drv/rainsensorqty"
#RAINSENSORQTY_PULSE=falling
#RAINSENSORQTY_WAIT=rising


# no other monitor process running...
if [[ -f "$RAINSENSORQTY_MONPID" ]] ; then
	pid="$( < "$RAINSENSORQTY_MONPID" )"
	if ps -fp $pid >/dev/null ; then
		drv_rainsensorqty_writelog $f "ERROR monitor process already running\n$( ps -fp $pid )"
		exit 1
	fi
fi

#drv_rainsensorqty_writelog $f "NORMAL - no rainmonitor process already running"
echo $$ > $RAINSENSORQTY_MONPID
drv_rainsensorqty_writelog $f "NORMAL - $$ pid monitor process started - see $RAINSENSORQTY_MONPID"
#echo "NORMAL: no raining monitor process  $( echo ; ps -ef | grep rain | grep monitor)"

# init variables
MMEACH="$RAINSENSORQTY_MMEACH"
counter=0

while true
do
	before=`date +%s`
	echo $GPIO -g wfi $gpio_port $RAINSENSORQTY_PULSE # falling 1->0
	$GPIO -g wfi $gpio_port $RAINSENSORQTY_PULSE # falling 1->0
	#sleep $(</tmp/secs_to_wait) # for testing only
	now=`date +%s`
	(( elapsed = now - before ))
	if (( $elapsed >= $RAINSENSORQTY_SECSBETWEENRAINEVENT )) ; then
		counter=0 
		drv_rainsensorqty_writelog $f "$elapsed seconds elapsed ( greater than $RAINSENSORQTY_SECSBETWEENRAINEVENT set ) since last rain, first $MMEACH mm rain"
		echo "$elapsed seconds elapsed ( greater than $RAINSENSORQTY_SECSBETWEENRAINEVENT set ) since last rain, first $MMEACH mm rain (first loop)" 
	fi
  	counter=$(( counter+=1 ))
	MMWATER=$( $JQ -n "$counter*$MMEACH" )
	drv_rainsensorqty_writelog $f "now is $MMWATER mm rain"
	echo "now is $MMWATER mm rain (loop $counter)"
	if (( $counter >= $RAINSENSORQTY_LOOPSFORSETRAINING )) ; then 
		drv_rainsensorqty_writelog $f "$MMWATER mm - irrigation to be stopped"
		echo "$MMWATER mm - irrigation to be stopped (loop $counter)"
		date +%s > ${RAINSENSORQTY_LASTRAIN}
		date > ${RAINSENSORQTY_LASTRAIN}_date
	fi
	echo $GPIO -g wfi $gpio_port $RAINSENSORQTY_WAIT # rising 0->1
	$GPIO -g wfi $gpio_port $RAINSENSORQTY_WAIT # rising 0->1
done
