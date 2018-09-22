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

	unlock

	trigger_event "init_before" ""

	# Inizializza i driver gpio
        for drv in "${list_drv[@]}"
        do
		echo "$(date) drv_${drv}_init"
		drv_${drv}_init
        done &> "$LOG_OUTPUT_DRV_FILE"

	# Imposta l'alimentazione con voltaggio negativo e setta i gpio in scrittura per le elettrovalvole bistabili
	if [ "$EV_MONOSTABLE" != "1" ]; then
		drv_supply_bistable_init "$SUPPLY_GPIO_1" "$SUPPLY_GPIO_2"
	fi

	# Elimina tutti gli stati delle elettrovalvole preesistenti
	rm -f "$STATUS_DIR"/ev*

	# Inizializza i gpio delle elettrovalvole e ne chiude l'alimentazione
	for i in $(seq $EV_TOTAL)
	do
		g=EV"$i"_GPIO
		drv_rele_init "${!g}"
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
		drv_rain_sensor_init "$RAIN_GPIO"
		log_write "Rain sensor initialized"
	else
		log_write "Rain sensor not present"
	fi

	trigger_event "init_after" ""
	log_write "End initialize"

}

#
# Elimina i file contenente i messaggi da inserire nel json status
#
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

	# Dall'alias dell'elettrovalvola recupero il numero e dal numero recupero gpio da usare
	ev_alias2number $1
	local EVNUM=$?
	local g=`ev_number2gpio $EVNUM`
	local EVNORAIN=`ev_number2norain $EVNUM`
	local EV_IS_REMOTE_VAR=EV"$EVNUM"_REMOTE
	local EV_IS_REMOTE=${!EV_IS_REMOTE_VAR}
	local EV_IS_MONOSTAVLE_VAR=EV"$EVNUM"_MONOSTABLE
	local EV_IS_MONOSTAVLE=${!EV_IS_MONOSTAVLE_VAR}

	if [ ! "$2" = "force" ] && [ "$EVNORAIN" != "1" ]; then
		if [[ "$NOT_IRRIGATE_IF_RAIN_ONLINE" -gt 0 && -f $STATUS_DIR/last_rain_online ]]; then
			local last_rain=`cat $STATUS_DIR/last_rain_online`
			local now=`date +%s`
			local dif=0
			let "dif = now - last_rain"
			if [ $dif -lt $NOT_IRRIGATE_IF_RAIN_ONLINE ]; then
				trigger_event "ev_not_open_for_rain_online" "$1" 
				trigger_event "ev_not_open_for_rain" "$1" 
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
				trigger_event "ev_not_open_for_rain_sensor" "$1" 
				trigger_event "ev_not_open_for_rain" "$1" 
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

	trigger_event "ev_open_before" "$1" "$2"
	if [ $? -ne 0 ]; then
		log_write "Solenoid '$1' not open due to external event"
		message_write 'warning' "Solenoid not open due to external event"
		return
	fi

	lock

	# Gestisce l'apertura dell'elettrovalvola in base alla tipologia (monostabile / bistabile) 
	if [ "$EV_MONOSTABLE" == "1" ] || [ "$EV_IS_REMOTE" == "1" ] || [ "$EV_IS_MONOSTABLE" == "1" ]; then
		drv_rele_close "$g"
		if [ $? -eq 1 ]; then
			unlock
			return		
		fi
	else
		supply_positive
		drv_rele_close "$g"
		sleep 1
		drv_rele_open "$g"
	fi

	ev_set_state $EVNUM $state

	trigger_event "ev_open_after" "$1" "$2"

	unlock

	log_write "Solenoid '$1' open"
	message_write "success" "Solenoid open"
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

	trigger_event "ev_open_in_before" "$3" "$4" "$1" "$2"

	gpio_alias2number $alias > /dev/null 2>&1

	minute_start=$(($minute_start + 1))
	minute_stop=$(($minute_start + $minute_stop))
	local cron_start=`date -d "today + $minute_start minutes" +"%M %H %d %m %u"`

	cron_del open_in $alias > /dev/null 2>&1
	cron_del open_in_stop $alias > /dev/null 2>&1

	if [ "$minute_start" -eq "1" ]; then
		ev_open $alias $force
		cron_start="- - - - -"
	else
		cron_add open_in $cron_start "$alias" "$force"
	fi
	
	local cron_stop=`date -d "today + $minute_stop minutes" +"%M %H %d %m %u"`
	cron_add open_in_stop $cron_stop "$alias" 

	message_write "success" "Scheduled start successfully performed"

	trigger_event "ev_open_in_after" "$3" "$4" "$cron_start" "$cron_stop"

	#echo $cron_start
	#echo $cron_stop

}


#
# Commuta un elettrovalvola nello stato chiuso
# $1 alias elettrovalvola
#
function ev_close {

	# Dall'alias dell'elettrovalvola recupero il numero e dal numero recupero gpio da usare
	ev_alias2number $1
	EVNUM=$?
	g=`ev_number2gpio $EVNUM`
	local EV_IS_REMOTE_VAR=EV"$EVNUM"_REMOTE
	local EV_IS_REMOTE=${!EV_IS_REMOTE_VAR}

	trigger_event "ev_close_before" "$1"

	lock

	# Gestisce l'apertura dell'elettrovalvola in base alla tipologia (monostabile / bistabile) 
	if [ "$EV_MONOSTABLE" == "1" ] || [ "$EV_IS_REMOTE" == "1" ]; then
		drv_rele_open "$g"
		if [ $? -eq 1 ]; then
			unlock
			return		
		fi
	else
		supply_negative
		drv_rele_close "$g"
		sleep 1
		drv_rele_open "$g"
	fi

	ev_set_state $EVNUM 0

	trigger_event "ev_close_after" "$1"

	unlock

	log_write "Solenoid '$1' close"
	message_write "success" "Solenoid close"

	cron_del open_in_stop $1 > /dev/null 2>&1
}

#
# Imposta l'alimentazione delle elettrovalvole con voltaggio positivo
#
function supply_positive {
	drv_supply_positive "$SUPPLY_GPIO_1" "$SUPPLY_GPIO_2"
}

#
# Imposta l'alimentazione delle elettrovalvole con voltaggio negativo
#
function supply_negative {
	drv_supply_negative "$SUPPLY_GPIO_1" "$SUPPLY_GPIO_2"
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
	local i=$1
	local g=EV"$i"_GPIO
	local gv=${!g}
	echo "$gv"
}

#
# Recupera il valore norain associato ad una elettrovalvola
# $1 numero elettrovalvola
#
function ev_number2norain {
	local i=$1
	local g=EV"$i"_NORAIN
	local gv=${!g}
	echo "$gv"
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
# Chiude tutte le elettrovalvole
# $1 indica se forzare la chiusura anche per le elettrovalvole con stato di inattività
#
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

#
# Stampa la lista degli alias delle elettrovalvole
#
function list_alias {

		for i in $(seq $EV_TOTAL)
		do
			local a=EV"$i"_ALIAS
			local al=${!a}
			echo $al
		done

}

#
# Stampa un json contanente lo status della centralina
# $1 .. $6 parametri opzionali
# 	- get_cron: aggiunge i dati relativi ai crontab delle scehdulazioni di apertura/chisura delle elettrovalvole
#	- get_cron_open_in: aggiunge i dati relativi ai crontab degli avvii ritardati eseguiti con il comando open_in
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
	local current_pid=$!
	local json_event="\"event\": {\"event\": \"$CURRENT_EVENT\", \"alias\": \"$CURRENT_EVENT_ALIAS\"}"

	if [ "$PARENT_PID" -gt "0" ]; then
		current_pid=$PARENT_PID
	fi

	local vret=""
	for i in $1 $2 $3 $4 $5 $6
        do
		if [ $i = "get_cron" ]; then
			with_get_cron="1"
		elif [[ "$i" == get_cron:* ]]; then
			with_get_cron="${i#get_cron:}"
		elif [ $i = "get_cron_open_in" ]; then
			with_get_cron_open_in="1"
		elif [[ "$i" == get_cron_open_in:* ]]; then
			with_get_cron_open_in="${i#get_cron_open_in:}"
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
		#json="$json\"$i\":{\"name\":\"$av\",\"state\":$sv}"
		json="$json\"$av\":{\"name\":\"$av\",\"state\":$sv}"
	done
	json="\"zones\":{$json}"

	local last_rain_sensor=`cat "$STATUS_DIR/last_rain_sensor" 2> /dev/null`
	local last_rain_online=`cat "$STATUS_DIR/last_rain_online" 2> /dev/null`

	local last_weather_online=`cat "$STATUS_DIR/last_weather_online" 2> /dev/null`
	if [[ ! -z "$last_weather_online" ]]; then
		json_last_weather_online=$last_weather_online
	fi
	if [ -f "$LAST_INFO_FILE.$current_pid" ]; then
		last_info=`cat "$LAST_INFO_FILE.$current_pid"`
	fi
	if [ -f "$LAST_WARNING_FILE.$current_pid" ]; then
		last_warning=`cat "$LAST_WARNING_FILE.$current_pid"`
	fi
	if [ -f "$LAST_SUCCESS_FILE.$current_pid" ]; then
		last_success=`cat "$LAST_SUCCESS_FILE.$current_pid"`
	fi
	local json_last_weather_online="\"last_weather_online\":$json_last_weather_online"
	local json_last_rain_sensor="\"last_rain_sensor\":\"$last_rain_sensor\""
	local json_last_rain_online="\"last_rain_online\":\"$last_rain_online\""
	local json_last_info="\"info\":\"$last_info\""	
	local json_last_warning="\"warning\":\"$last_warning\""	
	local json_last_success="\"success\":\"$last_success\""	

	local json_get_cron=""			
	if [ $with_get_cron != "0" ]; then
		local values_open="" 
		local values_close="" 
		local element_for=""
		if [ "$with_get_cron" == "1" ]; then
			element_for="$(seq $EV_TOTAL)"
		else
			ev_alias2number $with_get_cron
			element_for=$?
		fi
		for i in $element_for
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
	if [ $with_get_cron_open_in != "0" ]; then
		local values_open_in="" 
		local values_open_in_stop="" 
		local element_for=""
		if [ "$with_get_cron_open_in" == "1" ]; then
			element_for="$(seq $EV_TOTAL)"
		else
			ev_alias2number $with_get_cron_open_in
			element_for=$?
		fi
		for i in $element_for
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

	json="{$json_version,$json_event,$json,$json_last_weather_online,$json_error,$json_last_info,$json_last_warning,$json_last_success,$json_last_rain_online,$json_last_rain_sensor,$json_cron,$json_cron_open_in}"

	echo "$json"

	# {"zones":{"1":{"name":"Zona_1","state":1},"2":{"name":"Zona_2","state":0}}}

}

#
# Invia al broker mqtt il json contentente lo stato del sistema
#
# $1 parent pid (opzionale)
#
function mqtt_status {

	if [ ! $MQTT_ENABLE -eq 1 ]; then
		return
	fi

	if [ ! -z "$1" ]; then
		PARENT_PID=$1
	fi

	local js=$(json_status)
	$MOSQUITTO_PUB -h $MQTT_HOST -p $MQTT_PORT -u $MQTT_USER -P $MQTT_PWD -i $MQTT_CLIENT_ID -r -t "$MQTT_TOPIC" -m "$js"
}


#
# Mostra il i parametri dello script
#
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
	echo -e "\t$NAME_SCRIPT mqtt_status                                  send status in json format to mqtt broker"
	echo -e "\t$NAME_SCRIPT check_rain_online                            check rain from http://api.wunderground.com/"
	echo -e "\t$NAME_SCRIPT check_rain_sensor                            check rain from hardware sensor"
	echo -e "\t$NAME_SCRIPT close_all_for_rain                           close all solenoid if it's raining"
	echo -e "\t$NAME_SCRIPT close_all [force]                            close all solenoid"
	echo -e "\n"
	echo -e "\t$NAME_SCRIPT start_socket_server [force]                  start socket server, with 'force' parameter force close socket server if already open"
	echo -e "\t$NAME_SCRIPT stop_socket_server                           stop socket server"
	echo -e "\n"
	echo -e "\t$NAME_SCRIPT reboot                                       reboot system"
	echo -e "\t$NAME_SCRIPT poweroff                                     shutdown system"
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

	echo -e "\t$NAME_SCRIPT add_cron_open alias m h dom mon dow [disbled]	add crontab for open a solenoid"
	echo -e "\t$NAME_SCRIPT del_cron_open alias                          remove all crontab for open a solenoid"
	echo -e "\t$NAME_SCRIPT get_cron_open alias                          get all crontab for open a solenoid"
	echo -e "\t$NAME_SCRIPT del_cron_open_in alias                       remove all crontab for open_in a solenoid"
	echo -e "\t$NAME_SCRIPT add_cron_close alias m h dom mon dow [disabled]	add crontab for close a solenoid"
	echo -e "\t$NAME_SCRIPT del_cron_close alias                         remove all crontab for close a solenoid"
	echo -e "\t$NAME_SCRIPT get_cron_close alias                         get all crontab for close a solenoid"
	echo -e "\n"
	echo -e "\t$NAME_SCRIPT debug1 [parameter]|[parameter]|..]           Run debug code 1"
	echo -e "\t$NAME_SCRIPT debug2 [parameter]|[parameter]|..]           Run debug code 2"
}

#
# Mostra un json per una risposta di errore
# $1	codice errore
# $2	messaggio di errore
#
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

#
# Gestisce l'apertura di un lock
#
function lock {

	local max_time=10
	local current_time=$(($1 + 1))

	if mkdir "${LOCK_FILE}" &>/dev/null; then
		local foo=bar
	else
		if [ "$current_time" -gt "$max_time" ]; then
			log_write "Maximum locked time reached"
			sleep $max_time
			unlock
			exit 1
		fi
		log_write "Sleep 1 second for locked state"
		sleep 1
		lock $current_time
		return
	fi

}



#
# Chidue un lock
# 
function unlock {

	rmdir "${LOCK_FILE}" &>/dev/null

}



#
# Invia l'identificativo univoco ad uso statistico di utilizzo
#
function send_identifier {

	if [ "$NO_SEND_IDENTIFIER" == "1" ]; then
		return
	fi

	local FILE_ID="/tmp/pigarden.id"

	if [ -f "$FILE_ID" ]; then
		# Se il file non è più vecchio di un giorno esce
		local max_age_file=86400
		local time_file=`$STAT -c %Y "$FILE_ID"`
		local age_file=$((`date +"%s"` - $time_file ))
		#log_write "age_file=$age_file - max_age_file=$max_age_file"
		if [ "$age_file" -lt "$max_age_file" ]; then
			#log_write "Id troppo giovane ($age_file) esce e non esegue l'invio"
			return
		fi
	fi
	local ID=`/sbin/ifconfig | $GREP --color=never -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | /usr/bin/head -1 | /usr/bin/md5sum | $CUT -d" " -f 1`
	if [ -z "$ID" ]; then
		return;
	fi
	echo "$ID" > "$FILE_ID"

	log_write "Send installation identifier to collect usage"

	$CURL https://www.lejubila.net/statistic/collect_usage/piGarden/$ID/$VERSION/$SUB_VERSION/$RELEASE_VERSION > /dev/null 2>&1

}

#
# Spenge il sistema 
#
function exec_poweroff {
	trigger_event "exec_poweroff_before" 
	local PATH_SCRIPT=`$READLINK -f "$DIR_SCRIPT/scripts/poweroff.sh"`
        sleep 15
	. $PATH_SCRIPT
	trigger_event "exec_poweroff_after" 
}

#
# Spenge il sistema 
#
function exec_reboot {
	trigger_event "exec_reboot_before" 
	local PATH_SCRIPT=`$READLINK -f "$DIR_SCRIPT/scripts/reboot.sh"`
        sleep 15
	. $PATH_SCRIPT
	trigger_event "exec_reboot_after" 
}


#
# Converte da gradi a direzione
#
# $1 gradi
#
function deg2dir {
	local deg=$(echo $1 | $SED 's/\..*$//')
	local dir=""

	if [ "$deg" == "null" ]; then
		echo ""
		return
	fi

	# N	348.75 - 11.25
	if [ $deg -le 11 ]; then
		dir="North"

	# NNE	11.25 - 33.75
	elif [ $deg -le 33 ]; then
		dir="NNE"

	# NE	33.75 - 56.25
	elif [ $deg -le 56 ]; then
		dir="NE"

	# ENE	56.25 - 78.75
	elif [ $deg -le 78 ]; then
		dir="ENE"

	# E	78.75 - 101.25
	elif [ $deg -le 101 ]; then
		dir="East"

	# ESE	101.25 - 123.75
	elif [ $deg -le 123 ]; then
		dir="ESE"

	# SE	123.75 - 146.25
	elif [ $deg -le 146 ]; then
		dir="SE"

	# SSE	146.25 - 168.75
	elif [ $deg -le 168 ]; then
		dir="SSE"

	# S	168.75 - 191.25
	elif [ $deg -le 191 ]; then
		dir="South"

	# SSW	191.25 - 213.75
	elif [ $deg -le 213 ]; then
		dir="SSW"

	# SW	213.75 - 236.25
	elif [ $deg -le 236 ]; then
		dir="SW"

	# WSW	236.25 - 258.75
	elif [ $deg -le 258 ]; then
		dir="WSW"

	# W	258.75 - 281.25
	elif [ $deg -le 281 ]; then
		dir="West"

	# WNW	281.25 - 303.75
	elif [ $deg -le 303 ]; then
		dir="WNW"

	# NW	303.75 - 326.25
	elif [ $deg -le 326 ]; then
		dir="NW"

	# NNW	326.25 - 348.75
	elif [ $deg -le 348 ]; then
		dir="NNW"

	# N	348.75 - 11.25
	else
		dir="North"
	fi

	echo $dir

}

function debug1 {
	. "$DIR_SCRIPT/debug/debug1.sh"	
}

function debug2 {
	. "$DIR_SCRIPT/debug/debug2.sh"	
}

VERSION=0
SUB_VERSION=5
RELEASE_VERSION=9

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
LOCK_FILE="$TMP_PATH/piGarden.dir.lock"

if [ -f $CONFIG_ETC ]; then
	. $CONFIG_ETC
else
	echo -e "Config file not found in $CONFIG_ETC"
	exit 1
fi

. "$DIR_SCRIPT/include/drv.include.sh"
. "$DIR_SCRIPT/include/cron.include.sh"
. "$DIR_SCRIPT/include/socket.include.sh"
. "$DIR_SCRIPT/include/rain.include.sh"
. "$DIR_SCRIPT/include/events.include.sh"

LAST_INFO_FILE="$STATUS_DIR/last_info"
LAST_WARNING_FILE="$STATUS_DIR/last_warning"
LAST_SUCCESS_FILE="$STATUS_DIR/last_success"

CURRENT_EVENT=""
CURRENT_EVENT_ALIAS=""

PARENT_PID=0

if [ -z $LOG_OUTPUT_DRV_FILE ]; then
	LOG_OUTPUT_DRV_FILE="/dev/null"
fi

if [ -z "$EVENT_DIR" ]; then
	EVENT_DIR="$DIR_SCRIPT/events"
fi

if [ -z $WEATHER_SERVICE ]; then
	WEATHER_SERVICE="drv:wunderground"
else
	WEATHER_SERVICE="drv:$WEATHER_SERVICE"
fi

# Elimina il file di lock se più vecchio di 11 secondi
if [ -f "$LOCK_FILE" ]; then
	max_age_lock_file=11
	time_lock_file=`$STAT -c %Y "$LOCK_FILE"`
	age_lock_file=$((`date +"%s"` - $time_lock_file ))
	if [ "$age_lock_file" -gt "$max_age_lock_file" ]; then
		rm -f "$age_lock_file"
	fi
fi

send_identifier &
setup_drv

#echo "EV_MONOSTABLE=$EV_MONOSTABLE"

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

	mqtt_status)
		mqtt_status $2
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
		add_cron_open "$2" "$3" "$4" "$5" "$6" "$7" "$8"
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
		add_cron_close "$2" "$3" "$4" "$5" "$6" "$7" "$8"
		;;

	del_cron_close)
		del_cron_close $2 
		;;

	get_cron_close)
		get_cron_close $2
		;;
	
	reboot)
		exec_reboot
		;;

	poweroff)
		exec_poweroff
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

# Elimina eventuali file temporani utilizzati per la gestione dei cron e i messaggi per il sockt server
rm "$TMP_CRON_FILE" 2> /dev/null
rm "$TMP_CRON_FILE-2" 2> /dev/null

reset_messages &> /dev/null
