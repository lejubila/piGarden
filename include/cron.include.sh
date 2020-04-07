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
	local START=`$GREP -n "^# START cron $CRON_TYPE $CRON_ARG$" "$TMP_CRON_FILE"| $CUT -d : -f 1`
	local END=`$GREP -n "^# END cron $CRON_TYPE $CRON_ARG$" "$TMP_CRON_FILE"| $CUT -d : -f 1`
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

	trigger_event "cron_del_before" "$1" "$2"
	$SED "$START,${END}d" "$TMP_CRON_FILE" | $SED '$!N; /^\(.*\)\n\1$/!P; D' | $CRONTAB -
	rm "$TMP_CRON_FILE"
	trigger_event "cron_del_after" "$1" "$2"

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
	local CRON_DISABLED=""
	local PATH_SCRIPT=`$READLINK -f "$DIR_SCRIPT/$NAME_SCRIPT"`
	local TMP_CRON_FILE2="$TMP_CRON_FILE-2"

	if [ -z "$CRON_TYPE" ]; then
		echo "Cron type is empty" >&2
		log_write "Cron type is empty"
		return 1
	fi

	$CRONTAB -l > "$TMP_CRON_FILE"
	local START=`$GREP -n "^# START cron $CRON_TYPE $CRON_ARG$" "$TMP_CRON_FILE"| $CUT -d : -f 1`
	local END=`$GREP -n "^# END cron $CRON_TYPE $CRON_ARG$" "$TMP_CRON_FILE"| $CUT -d : -f 1`
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
			if [ "$CRON_ARG2" == "disabled" ]; then
				CRON_DISABLED="#"
			fi
			;;

		open_in)
			CRON_COMMAND="$PATH_SCRIPT open $CRON_ARG $CRON_ARG2"
			;;

		open_in_stop)
			CRON_COMMAND="$PATH_SCRIPT close $CRON_ARG"
			;;

		close)
			CRON_COMMAND="$PATH_SCRIPT close $CRON_ARG"
			if [ "$CRON_ARG2" == "disabled" ]; then
				CRON_DISABLED="#"
			fi
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
	echo "$CRON_DISABLED$CRON_M $CRON_H $CRON_DOM $CRON_MON $CRON_DOW $CRON_COMMAND" >> "$TMP_CRON_FILE2"
	echo "# END cron $CRON_TYPE $CRON_ARG" >> "$TMP_CRON_FILE2"

	trigger_event "cron_add_before" "$CRON_TYPE" "$CRON_ARG" "$CRON_DISABLED$CRON_M $CRON_H $CRON_DOM $CRON_MON $CRON_DOW $CRON_COMMAND"
	$CRONTAB "$TMP_CRON_FILE2"
	rm "$TMP_CRON_FILE" "$TMP_CRON_FILE2"
	trigger_event "cron_add_after" "$CRON_TYPE" "$CRON_ARG" "$CRON_DISABLED$CRON_M $CRON_H $CRON_DOM $CRON_MON $CRON_DOW $CRON_COMMAND"

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
	local START=`$GREP -n "^# START cron $CRON_TYPE $CRON_ARG$" "$TMP_CRON_FILE"| $CUT -d : -f 1`
	local END=`$GREP -n "^# END cron $CRON_TYPE $CRON_ARG$" "$TMP_CRON_FILE"| $CUT -d : -f 1`
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

#
# Imposta il cron di inizializzazione della centralina
#
function set_cron_init {

	cron_del "init" 2> /dev/null
	cron_add "init"

}

#
# Elimina il cron di inizializzazione della centralina
#
function del_cron_init {

	cron_del "init"

}

#
# Imposta il cron per l'avvio del socket server
#
function set_cron_start_socket_server {

	cron_del "start_socket_server" 2> /dev/null
	cron_add "start_socket_server"

}

#
# Elimina il cron per l'avvio del socket server
#
function del_cron_start_socket_server {

	cron_del "start_socket_server"
}

#
# Imposta il cron che esegue il controllo di presenza pioggia tramite sensore
#
function set_cron_check_rain_sensor {

	cron_del "check_rain_sensor" 2> /dev/null
	cron_add "check_rain_sensor"
}

#
# Elimina il cron che esegue il controllo di presenza pioggia tramite sensore
#
function del_cron_check_rain_sensor {

	cron_del "check_rain_sensor"

}

#
# Imposta il cron che esegue il controllo di presenza pioggia tramite servizio online
#
function set_cron_check_rain_online {

	cron_del "check_rain_online" 2> /dev/null
	cron_add "check_rain_online"
}

#
# Elimina il cron che esegue il controllo di presenza pioggia tramite servizio online
#
function del_cron_check_rain_online {

	cron_del "check_rain_online"

}

#
# Imposta il cron che gestisce la chiusura delle elettrovalvole in caso di pioggia
#
function set_cron_close_all_for_rain {

	cron_del "close_all_for_rain" 2> /dev/null
	cron_add "close_all_for_rain"
}

#
# Elimina il cron che gestisce la chiusura delle elettrovalvole in caso di pioggia
#
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
# $7	disabled
#
function add_cron_open {

	local exists=`alias_exists $1`
	if [ "check $exists" = "check FALSE" ]; then
		log_write "Alias $1 not found"
		echo "Alias $1 not found"
		return 1
	fi

	cron_add "open" "$2" "$3" "$4" "$5" "$6" "$1" "$7"

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
# $7	disabled
#
function add_cron_close {

	local exists=`alias_exists $1`
	if [ "check $exists" = "check FALSE" ]; then
		log_write "Alias $1 not found"
		echo "Alias $1 not found"
		return 1
	fi

	cron_add "close" "$2" "$3" "$4" "$5" "$6" "$1" "$7"

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

#
# Disabilita tutte le schedulazioni di apertura e chiusura elettrovalvole
#
function cron_disable_all_open_close {

	local a=""
	local al=""
	local cron=""

	#
	# Disabilita tutte le schedulazioni di apertura
	#
        for i in $(seq $EV_TOTAL)
        do
                a=EV"$i"_ALIAS
                al=${!a}
                local crons=`get_cron_open $al`
		if [[ ! -z "$crons" ]]; then
			del_cron_open $al
			IFS=$'\n'       # make newlines the only separator
			for cron in $crons
			do
				#echo "-- $cron --"
				CRON_M=`echo $cron | $CUT -d' ' -f1,1`
				CRON_H=`echo $cron | $CUT -d' ' -f2,2`
				CRON_DOM=`echo $cron | $CUT -d' ' -f3,3`
				CRON_MON=`echo $cron | $CUT -d' ' -f4,4`
				CRON_DOW=`echo $cron | $CUT -d' ' -f5,5`

				if [[ ${CRON_M:0:1} == "#" ]]; then
					CRON_M=${CRON_M:1:${#CRON_M}}
				fi
				#echo "++ $CRON_M $CRON_H $CRON_DOM $CRON_MON $CRON_DOW ++"

				add_cron_open $al "$CRON_M" "$CRON_H" "$CRON_DOM" "$CRON_MON" "$CRON_DOW" "disabled"
			done
		fi
		
        done


	#
	# Disabilita tutte le schedulazioni di chiusura
	#
        for i in $(seq $EV_TOTAL)
        do
                a=EV"$i"_ALIAS
                al=${!a}
                local crons=`get_cron_close $al`
		if [[ ! -z "$crons" ]]; then
			del_cron_close $al
			IFS=$'\n'       # make newlines the only separator
			for cron in $crons
			do
				#echo "-- $cron --"
				CRON_M=`echo $cron | $CUT -d' ' -f1,1`
				CRON_H=`echo $cron | $CUT -d' ' -f2,2`
				CRON_DOM=`echo $cron | $CUT -d' ' -f3,3`
				CRON_MON=`echo $cron | $CUT -d' ' -f4,4`
				CRON_DOW=`echo $cron | $CUT -d' ' -f5,5`

				if [[ ${CRON_M:0:1} == "#" ]]; then
					CRON_M=${CRON_M:1:${#CRON_M}}
				fi
				#echo "++ $CRON_M $CRON_H $CRON_DOM $CRON_MON $CRON_DOW ++"

				add_cron_close $al "$CRON_M" "$CRON_H" "$CRON_DOM" "$CRON_MON" "$CRON_DOW" "disabled"
			done
		fi
		
        done
}



#
# Attiva tutte le schedulazioni di apertura e chiusura elettrovalvole
#
function cron_enable_all_open_close {

	local a=""
	local al=""
	local cron=""

	#
	# Disabilita tutte le schedulazioni di apertura
	#
        for i in $(seq $EV_TOTAL)
        do
                a=EV"$i"_ALIAS
                al=${!a}
                local crons=`get_cron_open $al`
		if [[ ! -z "$crons" ]]; then
			del_cron_open $al
			IFS=$'\n'       # make newlines the only separator
			for cron in $crons
			do
				#echo "-- $cron --"
				CRON_M=`echo $cron | $CUT -d' ' -f1,1`
				CRON_H=`echo $cron | $CUT -d' ' -f2,2`
				CRON_DOM=`echo $cron | $CUT -d' ' -f3,3`
				CRON_MON=`echo $cron | $CUT -d' ' -f4,4`
				CRON_DOW=`echo $cron | $CUT -d' ' -f5,5`

				if [[ ${CRON_M:0:1} == "#" ]]; then
					CRON_M=${CRON_M:1:${#CRON_M}}
				fi
				#echo "++ $CRON_M $CRON_H $CRON_DOM $CRON_MON $CRON_DOW ++"

				add_cron_open $al "$CRON_M" "$CRON_H" "$CRON_DOM" "$CRON_MON" "$CRON_DOW"
			done
		fi
		
        done


	#
	# Disabilita tutte le schedulazioni di chiusura
	#
        for i in $(seq $EV_TOTAL)
        do
                a=EV"$i"_ALIAS
                al=${!a}
                local crons=`get_cron_close $al`
		if [[ ! -z "$crons" ]]; then
			del_cron_close $al
			IFS=$'\n'       # make newlines the only separator
			for cron in $crons
			do
				#echo "-- $cron --"
				CRON_M=`echo $cron | $CUT -d' ' -f1,1`
				CRON_H=`echo $cron | $CUT -d' ' -f2,2`
				CRON_DOM=`echo $cron | $CUT -d' ' -f3,3`
				CRON_MON=`echo $cron | $CUT -d' ' -f4,4`
				CRON_DOW=`echo $cron | $CUT -d' ' -f5,5`

				if [[ ${CRON_M:0:1} == "#" ]]; then
					CRON_M=${CRON_M:1:${#CRON_M}}
				fi
				#echo "++ $CRON_M $CRON_H $CRON_DOM $CRON_MON $CRON_DOW ++"

				add_cron_close $al "$CRON_M" "$CRON_H" "$CRON_DOM" "$CRON_MON" "$CRON_DOW"
			done
		fi
		
        done
}
