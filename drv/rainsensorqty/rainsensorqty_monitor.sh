#!/bin/bash -x
#
# Bash script to measure rainfall
# Author: androtto
# Url: 
#
#
# Scrive un messaggio nel file di log
# $1 log da scrivere
# 3 parameter expected in order:
#$gpio
#$RAINSENSORQTY_LOOPSFORSETRAINING
#$RAINSENSORQTY_SECSBETWEENRAINEVENT

function log_write {
        echo -e "`date`\t\t$1" >> $RAINSENSORQTY_LOG
}

###############
# MAIN
###############

if [ ! $# = 3 ] ; then 
 	echo "ERROR: 3 parameters expected"
fi

GPIO=$1
LOOPSFORSETRAINING=$2
SECSBETWEENRAINEVENT=$3

DIRNAME="$( dirname $0 )"
. /etc/piGarden.conf # test sulla presenza del file gia' fatti prima
. "$DIRNAME/config.include.sh"

#got from config file above:
#RAINSENSORQTY_LASTRAIN="$STATUS_DIR/rainsensorqty_lastrain"
#RAINSENSORQTY_LOG="$DIR_SCRIPT/log/rainsensorqty.log"
#RAINSENSORQTY_MONPID="$TMP_PATH/rainsensorqty_monitor.pid"
#RAINSENSORQTY_DIR="$DIR_SCRIPT/drv/rainsensorqty"
#RAINSENSORQTY_PULSE=falling
#RAINSENSORQTY_WAIT=rising


if [[ -f "$RAINSENSORQTY_MONPID" && -z "$RAINSENSORQTY_MONPID" ]] ; then
	pid=$( < "$RAINSENSORQTY_MONPID" )
	if ps -fp $pid >/dev/null ; then
		log_write "ERROR monitor process already running\n$( ps -fp $pid )"
		exit 1
	else
		log_write "no rainmonitor process running"
		echo $$ > $RAINSENSORQTY_MONPID
		log_write "$$ pid monitor process - see $RAINSENSORQTY_MONPID"
	fi
fi

MMEACH=0.303030303

counter=0

while true
do
	before=`date +%s`
	#gpio -g wfi $GPIO $RAINSENSORQTY_PULSE # falling 1->0
	sleep $(</tmp/secs_to_wait) # for testing only
	now=`date +%s`
	(( elapsed = now - before ))
	if (( elapsed >= $SECSBETWEENRAINEVENT )) ; then
		counter=0 
		log_write "sono passati $elapsed secondi ( > di $SECSBETWEENRAINEVENT ) dall'ultima precipitazione, reset counter"
		echo "sono passati $elapsed secondi ( > di $SECSBETWEENRAINEVENT ) dall'ultima precipitazione, reset counter"
	fi
  	counter=$(( counter+=1 ))
	MMWATER=$( $JQ -n "$counter*$MMEACH" )
	log_write "counter $counter -  $MMWATER mm acqua"
	echo "counter $counter -  $MMWATER mm acqua"
	if (( counter >= $LOOPSFORSETRAINING )) ; then 
		log_write "raggiunta acqua per impedire irrigazione: $MMWATER mm"
		echo "raggiunta acqua per impedire irrigazione: $MMWATER mm"
		date +%s > ${RAINSENSORQTY_LASTRAIN}
		date > ${RAINSENSORQTY_LASTRAIN}_date
	fi
	#gpio -g wfi $GPIO $RAINSENSORQTY_WAIT # rising 0->1
done
