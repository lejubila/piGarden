#!/bin/bash
#
# Bash script to manage an irrigation system built with a Raspberry Pi
# Author: david.bigagli@gmail.com
# Url: https://github.com/lejubila/piGarden
#

#
# Inizializza le elettrovalvole e l'alimentazione
#
function initialize {

	log_write "Run initialize"

	# Imposta l'alimentazione con voltaggio negativo e setta i gpio in scrittura
	$GPIO -g write $SUPPLY_GPIO_1 0
	$GPIO -g write $SUPPLY_GPIO_2 0
	$GPIO -g mode $SUPPLY_GPIO_1 out
	$GPIO -g mode $SUPPLY_GPIO_2 out

	# Elimina tutti gli stati delle elettrovalvole preesistenti
	rm -f "$STATUS_DIR"/*

	# Inizializza i gpio delle elettrovalvole e ne chiude l'alimentazione
	for i in $(seq $EV_TOTAL)
	do
		g=EV"$i"_GPIO
		$GPIO -g write ${!g} RELE_GPIO_OPEN 	# chiude l'alimentazione all'elettrovalvole
		$GPIO -g mode ${!g} out				# setta il gpio nella modalita di scrittura
		ev_set_state $i 0
	done

	# Chiude tutte le elettrovalvole
	for i in $(seq $EV_TOTAL)
	do
		a=EV"$i"_ALIAS
		al=${!a}
		ev_close $al
	done

	# Inizializza il sensore di rilevamento pioggia
	if [ -n "$RAIN_GPIO" ]; then 
		$GPIO -g mode $RAIN_GPIO in
		log_write "Rain sensor initialized"
	else
		log_write "Rain sensor not present"
	fi

	log_write "End initialize"

}

#
# Commuta un elettrovalvola nello stato aperto
# $1 alias elettrovalvola
# $2 se specificata la string "force" apre l'elettrovalvola anche se c'é pioggia
#
function ev_open {
	if [ ! "$2" = "force" ]; then
		if [[ "$NOT_IRRIGATE_IF_RAIN_ONLINE" -gt 0 && -f $STATUS_DIR/last_rain_online ]]; then
			local last_rain=`cat $STATUS_DIR/last_rain_online`
			local now=`date +%s`
			local dif=0
			let "dif = now - last_rain"
			if [ $dif -lt $NOT_IRRIGATE_IF_RAIN_ONLINE ]; then
				log_write "Solenoid '$1' not open for rain (online check)"
				return
			fi
		fi

		check_rain_sensor
		if [[ "$NOT_IRRIGATE_IF_RAIN_SENSOR" -gt 0 && -f $STATUS_DIR/last_rain_sensor ]]; then
			local last_rain=`cat $STATUS_DIR/last_rain_sensor`
			local now=`date +%s`
			local dif=0
			let "dif = now - last_rain"
			if [ $dif -lt $NOT_IRRIGATE_IF_RAIN_SENSOR ]; then
				log_write "Solenoid '$1' not open for rain (sensor check)"
				return
			fi
		fi
	fi

	log_write "Solenoid '$1' open"
	supply_positive
	#gpio_alias2number $1
	ev_alias2number $1
	EVNUM=$?
	ev_number2gpio $EVNUM
	g=$?
	$GPIO -g write $g $RELE_GPIO_CLOSE
	sleep 1
	$GPIO -g write $g $RELE_GPIO_OPEN
	ev_set_state $EVNUM 1 
}

#
# Commuta un elettrovalvola nello stato chiuso
# $1 alias elettrovalvola
#
function ev_close {
	log_write "Solenoid '$1' close"
	supply_negative
	#$GPIO_alias2number $1
	ev_alias2number $1
	EVNUM=$?
	ev_number2gpio $EVNUM
	g=$?
	$GPIO -g write $g $RELE_GPIO_CLOSE
	sleep 1
	$GPIO -g write $g $RELE_GPIO_OPEN
	ev_set_state $EVNUM 0
}

#
# Imposta l'alimentazione delle elettrovalvole con voltaggio positivo
#
function supply_positive {
	$GPIO -g write $SUPPLY_GPIO_1 $SUPPLY_GPIO_POS
	$GPIO -g write $SUPPLY_GPIO_2 $SUPPLY_GPIO_POS
}

#
# Imposta l'alimentazione delle elettrovalvole con voltaggio negativo
#
function supply_negative {
	$GPIO -g write $SUPPLY_GPIO_1 $SUPPLY_GPIO_NEG
	$GPIO -g write $SUPPLY_GPIO_2 $SUPPLY_GPIO_NEG
}

#
# Scrive un messaggio nel file di log
# $1 log da scrivere
#
function log_write {
	if [ -e "$LOG_FILE" ]; then
		local actualsize=$($WC -c <"$LOG_FILE")
		if [ $actualsize -ge $LOG_FILE_MAX_SIZE ]; then
			$GZIP $LOG_FILE
			$MV $LOG_FILE.gz $LOG_FILE.`date +%Y%m%d%H%M`.gz	
		fi
	fi

	echo -e "`date`\t\t$1" >> $LOG_FILE
}

#
# Imposta lo stgato di una elettrovalvola
# $1 numero dell'elettrovalvola 
# $2 stato da scrivere
#
function ev_set_state {
	echo "$2" > "$STATUS_DIR/ev$1"
}

#
# Legge lo stato di una elettrovalvola
#
function ev_get_state {
	return `cat "$STATUS_DIR/ev$1"`
}

#
# Passando un alias di un'elettrovalvola recupera il numero gpio associato 
# $1 alias elettrovalvola
#
function gpio_alias2number {
	for i in $(seq $EV_TOTAL)
	do
		g=EV"$i"_GPIO
		a=EV"$i"_ALIAS
		gv=${!g}
		av=${!a}
		if [ "$av" == "$1" ]; then
			return $gv
		fi
	done

	log_write "ERROR solenoid alias not found: $1"
	exit 1
}

#
# Recupera il numero di una elettrovalvola in base all'alias
# $1 alias dell'elettrovalvola
#
function ev_alias2number {
	for i in $(seq $EV_TOTAL)
	do
		a=EV"$i"_ALIAS
		av=${!a}
		if [ "$av" == "$1" ]; then
			return $i
		fi
	done

	log_write "ERROR solenoid alias not found: $1"
	exit 1
}

#
# Recupera il numero di gpio associato ad una elettrovalvola
# $1 numero elettrovalvola
#
function ev_number2gpio {
#	echo "numero ev $1"
	i=$1
	g=EV"$i"_GPIO
	gv=${!g}
#	echo "gv = $gv"
	return $gv
}

#
# Mostra lo stato di tutte le elettrovalvole
#
function ev_status_all {
	for i in $(seq $EV_TOTAL)
	do
		a=EV"$i"_ALIAS
		av=${!a}
		ev_get_state $i
		echo -e "$av: $?"
	done
}

#
# Mostra lo stato di una elettrovalvola
# $1 alias elettrovalvola
#
function ev_status {
	ev_alias2number $1
	i=$?
	ev_get_state $i
	local state=$?
	echo -e "$state"
	return $state
}

#
# Controlla se se piove tramite http://api.wunderground.com/
#
function check_rain_online {
	# http://www.wunderground.com/weather/api/d/docs?d=resources/phrase-glossary&MR=1
	$CURL http://api.wunderground.com/api/$WUNDERGROUND_KEY/conditions/q/$WUNDERGROUND_LOCATION.json > /tmp/check_rain_online.json
	local weather=`cat /tmp/check_rain_online.json | $JQ -M ".current_observation.weather"`
	local local_epoch=`cat /tmp/check_rain_online.json | $JQ -M -r ".current_observation.local_epoch"`
	#echo $weather
	if [ "$weather" = "null" ]; then
		log_write "check_rain_online - failed read online data"
	else
		log_write "check_rain_online - weather=$weather, local_epoch=$local_epoch"
		#if [[ "$weather" == *"Clear"* ]]; then
		if [[ "$weather" == *"Rain"* ]]; then
			#echo "ECCOMI!!!!!"
			echo $local_epoch > "$STATUS_DIR/last_rain_online"
			return $local_epoch	
		fi
	fi
}

#
# Controlla se se piove tramite sensore
#
function check_rain_sensor {

	if [ -n "$RAIN_GPIO" ]; then 
		local s=`$GPIO -g read $RAIN_GPIO`
		if [ "$s" = "$RAIN_GPIO_STATE" ]; then
			local local_epoch=`date +%s`
			echo $local_epoch > "$STATUS_DIR/last_rain_sensor"
			log_write "check_rain_sensor - now it's raining ($local_epoch)"
			return $local_epoch	
		else
			log_write "check_rain_sensor - now is not raining"
		fi
	else
		log_write "Rain sensor not present"
	fi

}

#
# Chiude tutte le elettrovalvole se sta piovendo
# Eseguie il controllo in tempo reale sul sensore hardware e sui dati dell'ultima chiamata eseguita online
#
function close_all_for_rain {

	local close_all=0
	local now=`date +%s`

	if [[ "$NOT_IRRIGATE_IF_RAIN_ONLINE" -gt 0 && -f $STATUS_DIR/last_rain_online ]]; then
		local last_rain=`cat $STATUS_DIR/last_rain_online`
		local dif=0
		let "dif = now - last_rain"
		if [ $dif -lt $NOT_IRRIGATE_IF_RAIN_ONLINE ]; then
			close_all=1
		fi
	fi

	if [[ "$NOT_IRRIGATE_IF_RAIN_SENSOR" -gt 0 && -f $STATUS_DIR/last_rain_sensor ]]; then
		local last_rain=`cat $STATUS_DIR/last_rain_sensor`
		local dif=0
		let "dif = now - last_rain"
		if [ $dif -lt $NOT_IRRIGATE_IF_RAIN_SENSOR ]; then
			close_all=1
		fi
	fi

	if [ "$close_all" = "1" ]; then
		for i in $(seq $EV_TOTAL)
		do
			local a=EV"$i"_ALIAS
			local al=${!a}
			ev_status $al
			local state=$?
			#echo "$al = $state"
			if [ "$state" = "1" ]; then
				ev_close $al
				log_write "close_all_for_rain - Close solenod '$al' for rain"
			fi
		done
	fi

}

function close_all {

		for i in $(seq $EV_TOTAL)
		do
			local a=EV"$i"_ALIAS
			local al=${!a}
			ev_status $al
			local state=$?
			#echo "$al = $state"
			if [[ "$state" = "1" || "$1" = "force" ]]; then
				ev_close $al
				log_write "close_all - Close solenod '$al' for rain"
			fi
		done

}

function list_alias {

		for i in $(seq $EV_TOTAL)
		do
			local a=EV"$i"_ALIAS
			local al=${!a}
			echo $al
		done

}

function json_status {
	local json=""
	for i in $(seq $EV_TOTAL)
	do
		local a=EV"$i"_ALIAS
		local av=${!a}
		ev_status $av > /dev/null
		local sv=$?
		if [ -n "$json" ]; then
			json="$json,"
		fi
		json="$json\"$i\":{\"name\":\"$av\",\"state\":$sv}"
	done
	json="\"zones\":{$json}"

	json="{$json}"

	echo $json

	# {"zones":{"1":{"name":"Zona_1","state":1},"2":{"name":"Zona_2","state":0}}}

}


function show_usage {
	echo -e "Usage:"
	echo -e "\t$NAME_SCRIPT init\t\tinitialize supply and solenoid in closed state"
	echo -e "\t$NAME_SCRIPT open alias [force]\topen a solenoid"
	echo -e "\t$NAME_SCRIPT close alias\t\tclose a solenoid"
	echo -e "\t$NAME_SCRIPT list_alias\t\tview list of aliases solenoid"
	echo -e "\t$NAME_SCRIPT ev_status alias\tshow status solenoid"
	echo -e "\t$NAME_SCRIPT ev_status_all \tshow status solenoids"
	echo -e "\t$NAME_SCRIPT json_status \tshow status in json format"
	echo -e "\t$NAME_SCRIPT check_rain_online \tcheck rain from http://api.wunderground.com/"
	echo -e "\t$NAME_SCRIPT check_rain_sensor \tcheck rain from hardware sensor"
	echo -e "\t$NAME_SCRIPT close_all_for_rain \tclose all solenoid if it's raining"
	echo -e "\t$NAME_SCRIPT close_all [force]\tclose all solenoid"
	echo -e "\t$NAME_SCRIPT debug1 [parameter]|[parameter]|..]\tRun debug code 1"
	echo -e "\t$NAME_SCRIPT debug2 [parameter]|[parameter]|..]\tRun debug code 2"
}

function debug1 {
	. "$DIR_SCRIPT/debug/debug1.sh"	
}

function debug2 {
	. "$DIR_SCRIPT/debug/debug1.sh"	
}

DIR_SCRIPT=`dirname $0`
NAME_SCRIPT=${0##*/}
CONFIG_ETC="/etc/piGarden.conf"

if [ -f $CONFIG_ETC ]; then
	. $CONFIG_ETC
else
	echo -e "Config file not found in $CONFIG_ETC"
	exit 1
fi

case "$1" in
	init) 
		initialize
		;;

	open)
		if [ "empty$2" == "empty" ]; then
			echo -e "Alias solenoid not specified"
		fi
		ev_open $2 $3
		;;

	close)
		if [ "empty$2" == "empty" ]; then
			echo -e "Alias solenoid not specified"
		fi
		ev_close $2
		;;

	list_alias)
		list_alias
		;;

	ev_status)
		ev_status $2
		;;

	ev_status_all)
		ev_status_all
		;;

	json_status)
		json_status
		;;

	check_rain_online)
		check_rain_online
		;;

	check_rain_sensor)
		check_rain_sensor
		;;

	close_all_for_rain)
		close_all_for_rain
		;;

	close_all)
		close_all $2
		;;

	debug1)
		debug1 $2 $3 $4 $5
		;;

	debug2)
		debug2 $2 $3 $4 $5
		;;


	*) 
		show_usage
		exit 1
		;;
esac



