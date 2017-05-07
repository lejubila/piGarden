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

function reset_messages {
	rm -f "$LAST_INFO_FILE.$!"
	rm -f "$LAST_WARNING_FILE.$!"
	rm -f "$LAST_SUCCESS_FILE.$!"
}

#
# Commuta un elettrovalvola nello stato aperto
# $1 alias elettrovalvola
# $2 se specificata la string "force" apre l'elettrovalvola anche se c'é pioggia
#
function ev_open {
	
	cron_del open_in $1 > /dev/null 2>&1

	if [ ! "$2" = "force" ]; then
		if [[ "$NOT_IRRIGATE_IF_RAIN_ONLINE" -gt 0 && -f $STATUS_DIR/last_rain_online ]]; then
			local last_rain=`cat $STATUS_DIR/last_rain_online`
			local now=`date +%s`
			local dif=0
			let "dif = now - last_rain"
			if [ $dif -lt $NOT_IRRIGATE_IF_RAIN_ONLINE ]; then
				log_write "Solenoid '$1' not open for rain (online check)"
				message_write "warning" "Solenoid not open for rain"
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
				message_write "warning" "Solenoid not open for rain"
				return
			fi
		fi
	fi

	local state=1
	if [ "$2" = "force" ]; then
		state=2
	fi

	log_write "Solenoid '$1' open"
	message_write "success" "Solenoid open"
	supply_positive
	ev_alias2number $1
	EVNUM=$?
	ev_number2gpio $EVNUM
	g=$?
	$GPIO -g write $g $RELE_GPIO_CLOSE
	sleep 1
	$GPIO -g write $g $RELE_GPIO_OPEN
	ev_set_state $EVNUM $state

}

#
# Commuta un elettrovalvola nello stato aperto
# $1 minute_start
# $2 minute_stop
# $3 alias elettrovalvola
# $4 se specificata la string "force" apre l'elettrovalvola anche se c'é pioggia
#
function ev_open_in {

	local minute_start=$1
	local minute_stop=$2
	local alias=$3
	local force=$4

	re='^[0-9]+$'
	if ! [[ $minute_start =~ $re ]] ; then
		echo -e "Time start of irrigation is wrong or not specified"
		message_write "warning" "Time start of irrigation is wrong or not specified"
		return 1
	fi
	if ! [[ $minute_stop =~ $re ]] ; then
		echo -e "Time stop of irrigation is wrong or not specified"
		message_write "warning" "Time stop of irrigation is wrong or not specified"
		return 1
	fi
	if [ $minute_stop -lt "1" ] ; then
		echo -e "Time stop of irrigation is wrong"
		message_write "warning" "Time stop of irrigation is wrong"
		return 1
	fi
	if [ "empty$alias" == "empty" ]; then
		echo -e "Alias solenoid not specified"
		message_write "warning" "Alias solenoid not specified"
		return 1
	fi
	gpio_alias2number $alias > /dev/null 2>&1

	minute_start=$(($minute_start + 1))
	minute_stop=$(($minute_start + $minute_stop))
	local cron_start=`date -d "today + $minute_start minutes" +"%M %H %d %m %u"`

	cron_del open_in $alias > /dev/null 2>&1
	cron_del open_in_stop $alias > /dev/null 2>&1

	if [ "$minute_start" -eq "1" ]; then
		ev_open $alias $force
	else
		cron_add open_in $cron_start "$alias" "$force"
	fi
	
	local cron_stop=`date -d "today + $minute_stop minutes" +"%M %H %d %m %u"`
	cron_add open_in_stop $cron_stop "$alias" 

	message_write "success" "Scheduled start successfully performed"

	#echo $cron_start
	#echo $cron_stop

}


#
# Commuta un elettrovalvola nello stato chiuso
# $1 alias elettrovalvola
#
function ev_close {
	log_write "Solenoid '$1' close"
	message_write "success" "Solenoid close"
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

	cron_del open_in_stop $1 > /dev/null 2>&1
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
# Scrive una tipologia di messaggio da inviare via socket server
# $1 tipo messaggio: info, warning, success
# $2 messaggio
#
function message_write {
	local file_message=""
	if [ "$1" = 'info' ]; then
		file_message="$LAST_INFO_FILE.$!"
	elif [ "$1" = "warning" ]; then
		file_message="$LAST_WARNING_FILE.$!"
	elif [ "$1" = "success" ]; then
		file_message="$LAST_SUCCESS_FILE.$!"
	else
		return
	fi
	
	echo "$2" > "$file_message"
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
	message_write "warning" "Solenoid alias not found"
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
	message_write "warning" "Solenoid alias not found"
	exit 1
}

#
# Verifica se un alias di una elettrovalvola esiste
# $1 alias dell'elettrovalvola
#
function alias_exists {
	local vret='FALSE'
	for i in $(seq $EV_TOTAL)
	do
		a=EV"$i"_ALIAS
		av=${!a}
		if [ "$av" == "$1" ]; then
			vret='TRUE'
		fi
	done

	echo $vret
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
	$CURL http://api.wunderground.com/api/$WUNDERGROUND_KEY/conditions/q/$WUNDERGROUND_LOCATION.json > $TMP_PATH/check_rain_online.json
	local weather=`cat $TMP_PATH/check_rain_online.json | $JQ -M ".current_observation.weather"`
	local current_observation=`cat $TMP_PATH/check_rain_online.json | $JQ -M ".current_observation"`
	local local_epoch=`cat $TMP_PATH/check_rain_online.json | $JQ -M -r ".current_observation.local_epoch"`
	#echo $weather
	#weather="[Light/Heavy] Drizzle"
	if [ "$weather" = "null" ]; then
		log_write "check_rain_online - failed read online data"
	else
		log_write "check_rain_online - weather=$weather, local_epoch=$local_epoch"
		#if [[ "$weather" == *"Clear"* ]]; then
		#if [[ "$weather" == *"Rain"* ]]; then
		if 	[[ "$weather" == *"Rain"* ]] || 
		 	[[ "$weather" == *"Snow"* ]] || 
		 	[[ "$weather" == *"Hail"* ]] || 
		 	[[ "$weather" == *"Ice"* ]] || 
		 	[[ "$weather" == *"Thunderstorm"* ]] || 
			[[ "$weather" == *"Drizzle"* ]]; 
		then
			#echo "ECCOMI!!!!!"
			echo $local_epoch > "$STATUS_DIR/last_rain_online"
			return $local_epoch	
		fi
		echo "$current_observation" > "$STATUS_DIR/last_weather_online"
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
				log_write "close_all_for_rain - Close solenoid '$al' for rain"
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
			if [[ "$state" -gt "0" || "$1" = "force" ]]; then
				ev_close $al
				log_write "close_all - Close solenoid '$al' for rain"
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

#
# $1 .. $6 parametri opzionali
#
function json_status {
	local json=""
	local json_last_weather_online="\"\""
	local json_version="\"version\":{\"ver\":$VERSION,\"sub\":$SUB_VERSION,\"rel\":$RELEASE_VERSION}"
	local json_error="\"error\":{\"code\":0,\"description\":\"\"}"
	local last_rain_sensor="";
	local last_rain_online="";
	local last_info=""
	local last_warning=""
	local last_success=""
	local with_get_cron="0"
	local with_get_cron_open_in="0"

	local vret=""
	for i in $1 $2 $3 $4 $5 $6
        do
		if [ $i = "get_cron" ]; then
			with_get_cron="1"
		fi
		if [ $i = "get_cron_open_in" ]; then
			with_get_cron_open_in="1"
		fi
	done

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

	local last_rain_sensor=`cat "$STATUS_DIR/last_rain_sensor" 2> /dev/null`
	local last_rain_online=`cat "$STATUS_DIR/last_rain_online" 2> /dev/null`

	local last_weather_online=`cat "$STATUS_DIR/last_weather_online" 2> /dev/null`
	if [[ ! -z "$last_weather_online" ]]; then
		json_last_weather_online=$last_weather_online
	fi
	if [ -f "$LAST_INFO_FILE.$!" ]; then
		last_info=`cat "$LAST_INFO_FILE.$!"`
	fi
	if [ -f "$LAST_WARNING_FILE.$!" ]; then
		last_warning=`cat "$LAST_WARNING_FILE.$!"`
	fi
	if [ -f "$LAST_SUCCESS_FILE.$!" ]; then
		last_success=`cat "$LAST_SUCCESS_FILE.$!"`
	fi
	local json_last_weather_online="\"last_weather_online\":$json_last_weather_online"
	local json_last_rain_sensor="\"last_rain_sensor\":\"$last_rain_sensor\""
	local json_last_rain_online="\"last_rain_online\":\"$last_rain_online\""
	local json_last_info="\"info\":\"$last_info\""	
	local json_last_warning="\"warning\":\"$last_warning\""	
	local json_last_success="\"success\":\"$last_success\""	

	local json_get_cron=""			
	if [ $with_get_cron = "1" ]; then
		local values_open="" 
		local values_close="" 
		for i in $(seq $EV_TOTAL)
		do
			local a=EV"$i"_ALIAS
			local av=${!a}
			local crn="$(cron_get "open" $av)"
			crn=`echo "$crn" | sed ':a;N;$!ba;s/\n/%%/g'`
			values_open="\"$av\": \"$crn\", $values_open"
			local crn="$(cron_get "close" $av)"
			crn=`echo "$crn" | sed ':a;N;$!ba;s/\n/%%/g'`
			values_close="\"$av\": \"$crn\", $values_close"
		done
		if [[ !  -z  $values_open ]]; then
			values_open="${values_open::-2}"
		fi
		if [[ !  -z  $values_close ]]; then
			values_close="${values_close::-2}"
		fi

		json_get_cron="\"open\": {$values_open},\"close\": {$values_close}"
	fi
	local json_cron="\"cron\":{$json_get_cron}"			

	local json_get_cron_open_in=""			
	if [ $with_get_cron_open_in = "1" ]; then
		local values_open_in="" 
		local values_open_in_stop="" 
		for i in $(seq $EV_TOTAL)
		do
			local a=EV"$i"_ALIAS
			local av=${!a}
			local crn="$(cron_get "open_in" $av)"
			crn=`echo "$crn" | sed ':a;N;$!ba;s/\n/%%/g'`
			values_open_in="\"$av\": \"$crn\", $values_open_in"
			local crn="$(cron_get "open_in_stop" $av)"
			crn=`echo "$crn" | sed ':a;N;$!ba;s/\n/%%/g'`
			values_open_in_stop="\"$av\": \"$crn\", $values_open_in_stop"
		done
		if [[ !  -z  $values_open_in ]]; then
			values_open_in="${values_open_in::-2}"
		fi
		if [[ !  -z  $values_open_in_stop ]]; then
			values_open_in_stop="${values_open_in_stop::-2}"
		fi

		json_get_cron_open_in="\"open_in\": {$values_open_in},\"open_in_stop\": {$values_open_in_stop}"
	fi
	local json_cron_open_in="\"cron_open_in\":{$json_get_cron_open_in}"			

	json="{$json_version,$json,$json_last_weather_online,$json_error,$json_last_info,$json_last_warning,$json_last_success,$json_last_rain_online,$json_last_rain_sensor,$json_cron,$json_cron_open_in}"

	echo "$json"

	# {"zones":{"1":{"name":"Zona_1","state":1},"2":{"name":"Zona_2","state":0}}}

}

#
# Elimina una tipoliga di schedulazione dal crontab dell'utente
# $1	tipologia del crontab
# $2	argomento della tipologia
#
function cron_del {

	local CRON_TYPE=$1
	local CRON_ARG=$2

	if [ -z "$CRON_TYPE" ]; then
		echo "Cron type is empty" >&2
		log_write "Cron type is empty"
		return 1
	fi

	$CRONTAB -l > "$TMP_CRON_FILE"
	local START=`$GREP -n "# START cron $CRON_TYPE $CRON_ARG" "$TMP_CRON_FILE"| $CUT -d : -f 1`
	local END=`$GREP -n "# END cron $CRON_TYPE $CRON_ARG" "$TMP_CRON_FILE"| $CUT -d : -f 1`
	local re='^[0-9]+$'

	if ! [[ "$START" =~ $re ]] && ! [[ "$END" =~ $re ]] ; then
		echo "$1 $2 cron is not present" >&2
		return
	fi
	if ! [[ $START =~ $re ]] ; then
  		echo "Cron start don't find" >&2
  		log_write "Cron start don't find"
		return 1
	fi
	if ! [[ $END =~ $re ]] ; then
  		echo "Cron end cron don't find" >&2
  		log_write "Cron end cron don't find"
		return 1
	fi
	if [ "$START" -gt "$END" ]; then
  		echo "Wrong position for start and end in cron" >&2
  		log_write "Wrong position for start and end in cron"
		return 1
	fi


	$SED "$START,${END}d" "$TMP_CRON_FILE" | $CRONTAB -
	#$CRONTAB "$TMP_CRON_FILE"
	rm "$TMP_CRON_FILE"

}

#
# Aggiunge una schedulazione nel crontab dell'utente
# $1	tipologia del crontab
# $2	minuto
# $3	ora
# $4	giorno del mese
# $5	mese
# $6	giorno della settimana
# $7	argomento della tipologia
# $8	secondo argomento della tipologia
#
function cron_add {

	local CRON_TYPE=$1
	local CRON_M=$2
	local CRON_H=$3
	local CRON_DOM=$4
	local CRON_MON=$5
	local CRON_DOW=$6
	local CRON_ARG=$7
	local CRON_ARG2=$8
	local CRON_COMMAND=""
	local PATH_SCRIPT=`$READLINK -f "$DIR_SCRIPT/$NAME_SCRIPT"`
	local TMP_CRON_FILE2="$TMP_CRON_FILE-2"

	if [ -z "$CRON_TYPE" ]; then
		echo "Cron type is empty" >&2
		log_write "Cron type is empty"
		return 1
	fi

	$CRONTAB -l > "$TMP_CRON_FILE"
	local START=`$GREP -n "# START cron $CRON_TYPE $CRON_ARG" "$TMP_CRON_FILE"| $CUT -d : -f 1`
	local END=`$GREP -n "# END cron $CRON_TYPE $CRON_ARG" "$TMP_CRON_FILE"| $CUT -d : -f 1`
	local re='^[0-9]+$'

	local NEW_CRON=0
	local PREVIUS_CONTENT=""

	if ! [[ $START =~ $re ]] && ! [[ $END =~ $re ]] ; then
  		NEW_CRON=1
	else
		if ! [[ $START =~ $re ]] ; then
  			echo "Cron start don't find" >&2
  			log_write "Cron start don't find"
			return 1
		fi
		if ! [[ $END =~ $re ]] ; then
  			echo "Cron end cron don't find" >&2
  			log_write "Cron end cron don't find"
			return 1
		fi
		START=$(($START + 1))
		END=$(($END - 1))

		if [ "$START" -gt "$END" ]; then
  			echo "Wrong position for start and end in cron" >&2
  			log_write "Wrong position for start and end in cron"
			return 1
		fi
		
		PREVIOUS_CONTENT=`$SED -n "$START,${END}p" "$TMP_CRON_FILE"`

	fi

	case "$CRON_TYPE" in

		init)
			CRON_M="@reboot"
			CRON_H=""
			CRON_DOM=""
			CRON_MON=""
			CRON_DOW=""
			CRON_COMMAND="$PATH_SCRIPT init"
			;;

		start_socket_server)
			CRON_M="@reboot"
			CRON_H=""
			CRON_DOM=""
			CRON_MON=""
			CRON_DOW=""
			CRON_COMMAND="$PATH_SCRIPT start_socket_server force"
			;;

		check_rain_online)
			CRON_M="*/3"
			CRON_H="*"
			CRON_DOM="*"
			CRON_MON="*"
			CRON_DOW="*"
			CRON_COMMAND="$PATH_SCRIPT check_rain_online 2> /tmp/check_rain_online.err"
			;;

		check_rain_sensor)
			CRON_M="*"
			CRON_H="*"
			CRON_DOM="*"
			CRON_MON="*"
			CRON_DOW="*"
			CRON_COMMAND="$PATH_SCRIPT check_rain_sensor 2> /tmp/check_rain_sensor.err"
			;;

		close_all_for_rain)
			CRON_M="*/5"
			CRON_H="*"
			CRON_DOM="*"
			CRON_MON="*"
			CRON_DOW="*"
			CRON_COMMAND="$PATH_SCRIPT close_all_for_rain 2> /tmp/close_all_for_rain.err 1> /dev/null"
			;;

		open)
			CRON_COMMAND="$PATH_SCRIPT open $CRON_ARG"
			;;

		open_in)
			CRON_COMMAND="$PATH_SCRIPT open $CRON_ARG $CRON_ARG2"
			;;

		open_in_stop)
			CRON_COMMAND="$PATH_SCRIPT close $CRON_ARG"
			;;

		close)
			CRON_COMMAND="$PATH_SCRIPT close $CRON_ARG"
			;;

		*)
			echo "Wrong cron type: $CRON_TYPE"
			log_write "Wrong cron type: $CRON_TYPE"
			;;

	esac

	if [ "$NEW_CRON" -eq "0" ]; then
		START=$(($START - 1))
		END=$(($END + 1))
		$SED "$START,${END}d" "$TMP_CRON_FILE" > "$TMP_CRON_FILE2"
	else
		cat "$TMP_CRON_FILE" > "$TMP_CRON_FILE2"
	fi

	if [ "$NEW_CRON" -eq "1" ]; then
		echo "" >> "$TMP_CRON_FILE2"
	fi
	echo "# START cron $CRON_TYPE $CRON_ARG" >> "$TMP_CRON_FILE2"
	if [ "$NEW_CRON" -eq "0" ]; then
		echo "$PREVIOUS_CONTENT" >> "$TMP_CRON_FILE2"
	fi
	echo "$CRON_M $CRON_H $CRON_DOM $CRON_MON $CRON_DOW $CRON_COMMAND" >> "$TMP_CRON_FILE2"
	echo "# END cron $CRON_TYPE $CRON_ARG" >> "$TMP_CRON_FILE2"

	$CRONTAB "$TMP_CRON_FILE2"
	rm "$TMP_CRON_FILE" "$TMP_CRON_FILE2"

}

#
# Legge una tipoliga di schedulazione dal crontab dell'utente
# $1	tipologia del crontab
# $2	argomento della tipologia
#
function cron_get {

	local CRON_TYPE=$1
	local CRON_ARG=$2

	if [ -z "$CRON_TYPE" ]; then
		echo "Cron type is empty" >&2
		log_write "Cron type is empty"
		return 1
	fi

	$CRONTAB -l > "$TMP_CRON_FILE"
	local START=`$GREP -n "# START cron $CRON_TYPE $CRON_ARG" "$TMP_CRON_FILE"| $CUT -d : -f 1`
	local END=`$GREP -n "# END cron $CRON_TYPE $CRON_ARG" "$TMP_CRON_FILE"| $CUT -d : -f 1`
	local re='^[0-9]+$'

	local PREVIUS_CONTENT=""

	if ! [[ $START =~ $re ]] && ! [[ $END =~ $re ]] ; then
  		PREVIUS_CONTENT=""
	else
		if ! [[ $START =~ $re ]] ; then
  			echo "Cron start don't find" >&2
  			log_write "Cron start don't find"
			return 1
		fi
		if ! [[ $END =~ $re ]] ; then
  			echo "Cron end cron don't find" >&2
  			log_write "Cron end cron don't find"
			return 1
		fi
		START=$(($START + 1))
		END=$(($END - 1))

		if [ "$START" -gt "$END" ]; then
  			echo "Wrong position for start and end in cron" >&2
  			log_write "Wrong position for start and end in cron"
			return 1
		fi
		
		PREVIOUS_CONTENT=`$SED -n "$START,${END}p" "$TMP_CRON_FILE"`
	fi

	echo "$PREVIOUS_CONTENT"

}

function set_cron_init {

	cron_del "init" 2> /dev/null
	cron_add "init"

}

function del_cron_init {

	cron_del "init"

}

function set_cron_start_socket_server {

	cron_del "start_socket_server" 2> /dev/null
	cron_add "start_socket_server"

}

function del_cron_start_socket_server {

	cron_del "start_socket_server"
}

function set_cron_check_rain_sensor {

	cron_del "check_rain_sensor" 2> /dev/null
	cron_add "check_rain_sensor"
}

function del_cron_check_rain_sensor {

	cron_del "check_rain_sensor"

}

function set_cron_check_rain_online {

	cron_del "check_rain_online" 2> /dev/null
	cron_add "check_rain_online"
}

function del_cron_check_rain_online {

	cron_del "check_rain_online"

}

function set_cron_close_all_for_rain {

	cron_del "close_all_for_rain" 2> /dev/null
	cron_add "close_all_for_rain"
}

function del_cron_close_all_for_rain {

	cron_del "close_all_for_rain"

}

#
# Aggiunge una schedulazione cron per aprire una elettrovalvola
# $1	alias elettrovalvola
# $2	minuto cron
# $3	ora cron
# $4	giorno del mese cron
# $5	mese cron
# $6	giorno della settimana cron
#
function add_cron_open {

	local exists=`alias_exists $1`
	if [ "check $exists" = "check FALSE" ]; then
		log_write "Alias $1 not found"
		echo "Alias $1 not found"
		return 1
	fi

	cron_add "open" "$2" "$3" "$4" "$5" "$6" "$1"

}

#
# Cancella tutte le schedulazioni cron per aprire una elettrovalvola
# $1	alias elettrovalvola
#
function del_cron_open {

	local exists=`alias_exists $1`
	if [ "check $exists" = "check FALSE" ]; then
		log_write "Alias $1 not found"
		echo "Alias $1 not found"
		return 1
	fi

	cron_del "open" $1	

}

#
# Legge tutte le schedulazioni cron per aprire una elettrovalvola
# $1	alias elettrovalvola
#
function get_cron_open {

	local exists=`alias_exists $1`
	if [ "check $exists" = "check FALSE" ]; then
		log_write "Alias $1 not found"
		echo "Alias $1 not found"
		return 1
	fi

	cron_get "open" $1	

}

#
# Cancella tutte le schedulazioni cron per aprire/chiudere una elettrovalvola in modo ritardato
# $1	alias elettrovalvola
#
function del_cron_open_in {

	local exists=`alias_exists $1`
	if [ "check $exists" = "check FALSE" ]; then
		log_write "Alias $1 not found"
		echo "Alias $1 not found"
		return 1
	fi

	cron_del "open_in" $1	
	cron_del "open_in_stop" $1	

}

#
# Legge tutte le schedulazioni cron per chiudere una elettrovalvola
# $1	alias elettrovalvola
#
function get_cron_close {

	local exists=`alias_exists $1`
	if [ "check $exists" = "check FALSE" ]; then
		log_write "Alias $1 not found"
		echo "Alias $1 not found"
		return 1
	fi

	cron_get "close" $1	

}

#
# Aggiunge una schedulazione cron per chiudere una elettrovalvola
# $1	alias elettrovalvola
# $2	minuto cron
# $3	ora cron
# $4	giorno del mese cron
# $5	mese cron
# $6	giorno della settimana cron
#
function add_cron_close {

	local exists=`alias_exists $1`
	if [ "check $exists" = "check FALSE" ]; then
		log_write "Alias $1 not found"
		echo "Alias $1 not found"
		return 1
	fi

	cron_add "close" "$2" "$3" "$4" "$5" "$6" "$1"

}

#
# Cancella tutte le schedulazioni cron per chiudere una elettrovalvola
# $1	alias elettrovalvola
#
function del_cron_close {

	local exists=`alias_exists $1`
	if [ "check $exists" = "check FALSE" ]; then
		log_write "Alias $1 not found"
		echo "Alias $1 not found"
		return 1
	fi

	cron_del "close" $1	

}



function show_usage {
	echo -e "piGarden v. $VERSION.$SUB_VERSION.$RELEASE_VERSION"
	echo -e ""
	echo -e "Usage:"
	echo -e "\t$NAME_SCRIPT init                                         initialize supply and solenoid in closed state"
	echo -e "\t$NAME_SCRIPT open alias [force]                           open a solenoid"
	echo -e "\t$NAME_SCRIPT open_in minute_start minute_stop alias [force]  open a solenoid in minute_start for minute_stop"
	echo -e "\t$NAME_SCRIPT close alias                                  close a solenoid"
	echo -e "\t$NAME_SCRIPT list_alias                                   view list of aliases solenoid"
	echo -e "\t$NAME_SCRIPT ev_status alias                              show status solenoid"
	echo -e "\t$NAME_SCRIPT ev_status_all                                show status solenoids"
	echo -e "\t$NAME_SCRIPT json_status [get_cron|get_cron_open_in]      show status in json format"
	echo -e "\t$NAME_SCRIPT check_rain_online                            check rain from http://api.wunderground.com/"
	echo -e "\t$NAME_SCRIPT check_rain_sensor                            check rain from hardware sensor"
	echo -e "\t$NAME_SCRIPT close_all_for_rain                           close all solenoid if it's raining"
	echo -e "\t$NAME_SCRIPT close_all [force]                            close all solenoid"
	echo -e "\t$NAME_SCRIPT start_socket_server [force]                  start socket server, with 'force' parameter force close socket server if already open"
	echo -e "\t$NAME_SCRIPT stop_socket_server                           stop socket server"
	echo -e "\n"
	echo -e "\t$NAME_SCRIPT set_cron_init                                set crontab for initialize control unit"
	echo -e "\t$NAME_SCRIPT del_cron_init                                remove crontab for initialize control unit"
	echo -e "\t$NAME_SCRIPT set_cron_start_socket_server                 set crontab for start socket server"
	echo -e "\t$NAME_SCRIPT del_cron_start_socket_server                 remove crontab for start socket server"
	echo -e "\t$NAME_SCRIPT set_cron_check_rain_sensor                   set crontab for check rein from sensor"
	echo -e "\t$NAME_SCRIPT del_cron_check_rain_sensor                   remove crontab for check rein from sensor"
	echo -e "\t$NAME_SCRIPT set_cron_check_rain_online                   set crontab for check rein from online service"
	echo -e "\t$NAME_SCRIPT del_cron_check_rain_online                   remove crontab for check rein from online service"
	echo -e "\t$NAME_SCRIPT set_cron_close_all_for_rain                  set crontab for close all solenoid when raining"
	echo -e "\t$NAME_SCRIPT del_cron_close_all_for_rain                  remove crontab for close all solenoid when raining"

	echo -e "\t$NAME_SCRIPT add_cron_open alias m h dom mon dow          add crontab for open a solenoid"
	echo -e "\t$NAME_SCRIPT del_cron_open alias                          remove all crontab for open a solenoid"
	echo -e "\t$NAME_SCRIPT get_cron_open alias                          get all crontab for open a solenoid"
	echo -e "\t$NAME_SCRIPT del_cron_open_in alias                       remove all crontab for open_in a solenoid"
	echo -e "\t$NAME_SCRIPT add_cron_close alias m h dom mon dow         add crontab for close a solenoid"
	echo -e "\t$NAME_SCRIPT del_cron_close alias                         remove all crontab for close a solenoid"
	echo -e "\t$NAME_SCRIPT get_cron_close alias                         get all crontab for close a solenoid"
	echo -e "\n"
	echo -e "\t$NAME_SCRIPT debug1 [parameter]|[parameter]|..]           Run debug code 1"
	echo -e "\t$NAME_SCRIPT debug2 [parameter]|[parameter]|..]           Run debug code 2"
}

function start_socket_server {

	rm -f "$TCPSERVER_PID_FILE"
	echo $TCPSERVER_PID_SCRIPT > "$TCPSERVER_PID_FILE"
	$TCPSERVER -v -RHl0 $TCPSERVER_IP $TCPSERVER_PORT $0 socket_server_command 

	#if [ $? -eq 0 ]; then
	#	echo $TCPSERVER_PID_SCRIPT > "$TCPSERVER_PID_FILE"
	#	trap stop_socket_server EXIT

	#	log_write "start socket server ";
	#	return 0
	#else
	#	log_write "start socket server failed";
	#	return 1
	#fi
}

function stop_socket_server {

        if [ ! -f "$TCPSERVER_PID_FILE" ]; then
                echo "Daemon is not running"
                exit 1
        fi

	log_write "stop socket server"

        kill -9 $(list_descendants `cat "$TCPSERVER_PID_FILE"`) 2> /dev/null
        kill -9 `cat "$TCPSERVER_PID_FILE"` 2> /dev/null
        rm -f "$TCPSERVER_PID_FILE"

}

function socket_server_command {

	RUN_FROM_TCPSERVER=1

	local line=""
	read line
	line=$(echo "$line " | $TR -d '[\r\n]')
	arg1=$(echo "$line " | $CUT -d ' ' -f1)
	arg2=$(echo "$line " | $CUT -d ' ' -f2)
	arg3=$(echo "$line " | $CUT -d ' ' -f3)
	arg4=$(echo "$line " | $CUT -d ' ' -f4)
	arg5=$(echo "$line " | $CUT -d ' ' -f5)
	arg6=$(echo "$line " | $CUT -d ' ' -f6)
	arg7=$(echo "$line " | $CUT -d ' ' -f7)

	log_write "socket connection from: $TCPREMOTEIP - command: $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7"
	
	reset_messages &> /dev/null

	case "$arg1" in
        	status)
			json_status $arg2 $arg3 $arg4 $arg5 $arg6 $arg7
			;;

		open)
	                if [ "empty$arg2" == "empty" ]; then
        	                json_error 0 "Alias solenoid not specified"
			else
                		ev_open $arg2 $arg3 &> /dev/null
				json_status
			fi
			;;

		open_in)
			ev_open_in $arg2 $arg3 $arg4 $arg5 &> /dev/null
			json_status "get_cron_open_in"
			;;	

		close)
	                if [ "empty$arg2" == "empty" ]; then
        	                json_error 0 "Alias solenoid not specified"
			else
                		ev_close $arg2 &> /dev/null
				json_status
                	fi
			;;

		set_general_cron)
			local vret=""
			for i in $arg2 $arg3 $arg4 $arg5 $arg6 $arg7
		        do
				if [ $i = "set_cron_init" ]; then
					vret="$(vret)`set_cron_init`"
				elif [ $i = "set_cron_start_socket_server" ]; then
					vret="$(vret)`set_cron_start_socket_server`"
				elif [ $i = "set_cron_check_rain_sensor" ]; then
					vret="$(vret)`set_cron_check_rain_sensor`"
				elif [ $i = "set_cron_check_rain_online" ]; then
					vret="$(vret)`set_cron_check_rain_online`"
				elif [ $i = "set_cron_close_all_for_rain" ]; then
					vret="$(vret)`set_cron_close_all_for_rain`"
				fi
			done

			if [[ ! -z $vret ]]; then
				json_error 0 "Cron set failed"
				log_write "Cron set failed: $vret"
			else
				message_write "success" "Cron set successfull"
				json_status
			fi

			;;

		del_cron_open)
			local vret=""

			vret=`del_cron_open $arg2`

			if [[ ! -z $vret ]]; then
				json_error 0 "Cron set failed"
				log_write "Cron del failed: $vret"
			else
				message_write "success" "Cron set successfull"
				json_status
			fi

			;;

		del_cron_open_in)
			local vret=""

			vret=`del_cron_open_in $arg2`

			if [[ ! -z $vret ]]; then
				json_error 0 "Cron del failed"
				log_write "Cron del failed: $vret"
			else
				message_write "success" "Scheduled start successfully deleted"
				json_status "get_cron_open_in"
			fi

			;;


		del_cron_close)
			local vret=""

			vret=`del_cron_close $arg2`

			if [[ ! -z $vret ]]; then
				json_error 0 "Cron set failed"
				log_write "Cron set failed: $vret"
			else
				message_write "success" "Cron set successfull"
				json_status
			fi

			;;

			add_cron_open)
				local vret=""

			vret=`add_cron_open "$arg2" "$arg3" "$arg4" "$arg5" "$arg6" "$arg7"`

			if [[ ! -z $vret ]]; then
				json_error 0 "Cron set failed"
				log_write "Cron set failed: $vret"
			else
				message_write "success" "Cron set successfull"
				json_status
			fi

			;;

		add_cron_close)
			local vret=""

			vret=`add_cron_close "$arg2" "$arg3" "$arg4" "$arg5" "$arg6" "$arg7"`

			if [[ ! -z $vret ]]; then
				json_error 0 "Cron set failed"
				log_write "Cron set failed: $vret"
			else
				message_write "success" "Cron set successfull"
				json_status
			fi

			;;

		*)
			json_error 0 "invalid command"
			;;

	esac
	
	reset_messages &> /dev/null

}

json_error()
{
	echo "{\"error\":{\"code\":$1,\"description\":\"$2\"}}"
}

list_descendants ()
{
  local children=$(ps -o pid= --ppid "$1")

  for pid in $children
  do
    list_descendants "$pid"
  done

  echo "$children"
}

function debug1 {
	. "$DIR_SCRIPT/debug/debug1.sh"	
}

function debug2 {
	. "$DIR_SCRIPT/debug/debug1.sh"	
}

VERSION=0
SUB_VERSION=2
RELEASE_VERSION=3

DIR_SCRIPT=`dirname $0`
NAME_SCRIPT=${0##*/}
CONFIG_ETC="/etc/piGarden.conf"
TMP_PATH="/run/shm"
if [ ! -d "$TMP_PATH" ]; then
	TMP_PATH="/tmp"
fi
TCPSERVER_PID_FILE="$TMP_PATH/piGardenTcpServer.pid"
TCPSERVER_PID_SCRIPT=$$
RUN_FROM_TCPSERVER=0
TMP_CRON_FILE="$TMP_PATH/pigarden.user.cron.$$"

if [ -f $CONFIG_ETC ]; then
	. $CONFIG_ETC
else
	echo -e "Config file not found in $CONFIG_ETC"
	exit 1
fi

LAST_INFO_FILE="$STATUS_DIR/last_info"
LAST_WARNING_FILE="$STATUS_DIR/last_worning"
LAST_SUCCESS_FILE="$STATUS_DIR/last_success"

case "$1" in
	init) 
		initialize
		;;

	open)
		if [ "empty$2" == "empty" ]; then
			echo -e "Alias solenoid not specified"
			exit 1
		fi
		ev_open $2 $3
		;;

	open_in)
		ev_open_in $2 $3 $4 $5
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
		json_status $2 $3 $4 $5 $6
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

        start_socket_server)
                if [ -f "$TCPSERVER_PID_FILE" ]; then
                        echo "Daemon is already running, use \"$0 stop_socket_server\" to stop the service"

			if [ "x$2" == "xforce" ]; then
				sleep 5
				stop_socket_server
			else
                        	exit 1
			fi
                fi

                nohup $0 start_socket_server_daemon > /dev/null 2>&1 &

                echo "Daemon is started widh pid $!"
		log_write "start socket server with pid $!"
                ;;

	start_socket_server_daemon)
		start_socket_server
		;;

	stop_socket_server)
		stop_socket_server
		;;

	socket_server_command)
		socket_server_command
		;;

	set_cron_init)
		set_cron_init
		;;

	del_cron_init)
		del_cron_init
		;;

	set_cron_start_socket_server)
		set_cron_start_socket_server
		;;

	del_cron_start_socket_server)
		del_cron_start_socket_server
		;;

	set_cron_check_rain_sensor)
		set_cron_check_rain_sensor
		;;

	del_cron_check_rain_sensor)
		del_cron_check_rain_sensor
		;;

	set_cron_check_rain_online)
		set_cron_check_rain_online
		;;

	del_cron_check_rain_online)
		del_cron_check_rain_online
		;;

	set_cron_close_all_for_rain)
		set_cron_close_all_for_rain
		;;

	del_cron_close_all_for_rain)
		del_cron_close_all_for_rain
		;;

	add_cron_open)
		add_cron_open "$2" "$3" "$4" "$5" "$6" "$7"
		;;

	del_cron_open)
		del_cron_open $2 
		;;

	del_cron_open_in)
		del_cron_open_in $2 
		;;

	get_cron_open)
		get_cron_open $2
		;;

	add_cron_close)
		add_cron_close "$2" "$3" "$4" "$5" "$6" "$7"
		;;

	del_cron_close)
		del_cron_close $2 
		;;

	get_cron_close)
		get_cron_close $2
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

# Elimina eventuali file temporane utilizzati per la gestione dei cron
rm "$TMP_CRON_FILE" 2> /dev/null
rm "$TMP_CRON_FILE-2" 2> /dev/null

