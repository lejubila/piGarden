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

	log_write "Solenoid '$1' open"
	message_write "success" "Solenoid open"
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
	message_write "error" "Solenoid alias not found"
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
	message_write "error" "Solenoid alias not found"
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
	local current_observation=`cat /tmp/check_rain_online.json | $JQ -M ".current_observation"`
	local local_epoch=`cat /tmp/check_rain_online.json | $JQ -M -r ".current_observation.local_epoch"`
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
			if [[ "$state" = "1" || "$1" = "force" ]]; then
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

function json_status {
	local json=""
	local json_last_weather_online="\"\""
	local json_error="\"error\":{\"code\":0,\"description\":\"\"}"
	local last_rain_sensor="";
	local last_rain_online="";
	local last_info=""
	local last_warning=""
	local last_success=""
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

	json="{$json,$json_last_weather_online,$json_error,$json_last_info,$json_last_warning,$json_last_success,$json_last_rain_online,$json_last_rain_sensor}"

	echo $json

	# {"zones":{"1":{"name":"Zona_1","state":1},"2":{"name":"Zona_2","state":0}}}

}

function cron_del_check_rain_sensor {

	TMP_CRON_FILE="/tmp/pigarden.user.cron"
	$CRONTAB -l > /tmp/pigarden.user.cron
	local START=`$GREP -n "# START cron_del_check_rain_sensor"`
	local END=`$GREP -n "# END cron_del_check_rain_sensor"`
	local re='^[0-9]+$'
	if ! [[ $START =~ $re ]] ; then
  		echo "Cron start don't find" >&2
		return
	fi
	if ! [[ $END =~ $re ]] ; then
  		echo "Cron end cron don't find" >&2
		return
	fi
	if [ "$START" -gt "$END" ]; then
  		echo "Wrong position for start and end in cron" >&2
		return
	fi
	$SED '$START,$ENDd' $TMP_CRON_FILE
	$CRONTAB $TMP_CRON_FILE

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
	echo -e "\t$NAME_SCRIPT start_socket_server\tstart socket server"
	echo -e "\t$NAME_SCRIPT stop_socket_server\tstop socket server"
	echo -e "\t$NAME_SCRIPT cron_set_check_rain_sensor\tset crontab for check rein from sensor"
	echo -e "\t$NAME_SCRIPT cron_del_check_rain_sensor\tremove crontab for check rein from sensor"
	echo -e "\t$NAME_SCRIPT debug1 [parameter]|[parameter]|..]\tRun debug code 1"
	echo -e "\t$NAME_SCRIPT debug2 [parameter]|[parameter]|..]\tRun debug code 2"
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

	log_write "socket connection from: $TCPREMOTEIP - command: $arg1 $arg2 $arg3 $arg4 $arg5"
	
	reset_messages &> /dev/null

	case "$arg1" in
        	status)
			json_status
			;;

		open)
	                if [ "empty$arg2" == "empty" ]; then
        	                json_error 0 "Alias solenoid not specified"
			else
                		ev_open $arg2 $arg3 &> /dev/null
				json_status
			fi
			;;

		close)
	                if [ "empty$arg2" == "empty" ]; then
        	                json_error 0 "Alias solenoid not specified"
			else
                		ev_close $arg2 &> /dev/null
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

DIR_SCRIPT=`dirname $0`
NAME_SCRIPT=${0##*/}
CONFIG_ETC="/etc/piGarden.conf"
TCPSERVER_PID_FILE="/tmp/piGardenTcpServer.pid"
TCPSERVER_PID_SCRIPT=$$
RUN_FROM_TCPSERVER=0
TMP_CRON_FILE="/tmp/pigarden.user.cron"

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

        start_socket_server)
                if [ -f "$TCPSERVER_PID_FILE" ]; then
                        echo "Daemon is already running, use \"$0 stop_socket_server\" to stop the service"
                        exit 1
                fi

                nohup $0 start_socket_server_daemon > /dev/null 2>&1 &

	        #if [ -f "$TCPSERVER_PID_FILE" ]; then
                echo "Daemon is started widh pid $!"
		log_write "start socket server with pid $!"
		#else
		#	echo "start socket server failed";
		#fi
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

	cron_set_check_rain_sensor)
		cron_set_check_rain_sensor
		;;

	cron_del_check_rain_sensor)
		cron_del_check_rain_sensor
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



