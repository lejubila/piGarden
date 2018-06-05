declare -a list_drv

function setup_drv { 

	#declare -a list_drv
	list_drv=()

        # Inizializza i driver per le elettrovalvole
        for i in $(seq $EV_TOTAL)
        do
                local a=EV"$i"_GPIO
                local gpio="${!a}"
		if [[ "$gpio" == drv:* ]]; then
			local drv=`echo $gpio | $CUT -d':' -f2,2`
			if [[ ! " ${list_drv[@]} " =~ " ${drv} " ]]; then
				list_drv+=("$drv")
			fi
		fi
        done

	# Inizializza i driver per gli altri gpio
	for gpio in "$SUPPLY_GPIO_1" "$SUPPLY_GPIO_2" "$RAIN_GPIO" "$WEATHER_SERVICE"
	do
		if [[ "$gpio" == drv:* ]]; then
			local drv=`echo $gpio | $CUT -d':' -f2,2`
			if [[ ! " ${list_drv[@]} " =~ " ${drv} " ]]; then
				list_drv+=("$drv")
			fi
		fi
	done

	local file_drv
	for drv in "${list_drv[@]}"
	do
		for callback in config common init rele supply rainsensor rainonline setup
		do
			file_drv="$DIR_SCRIPT/drv/$drv/$callback.include.sh"
			if [ -f "$file_drv" ]; then
				#drv_avalible[$drv]="${drv_avalible[$drv]}#$callback#"
				#echo ${drv_avalible[$drv]}
				. "$file_drv"

				if [ $callback == "setup" ]; then
					local fnc="drv_${drv}_setup"
					echo "$(date) $fnc" >> "$LOG_OUTPUT_DRV_FILE"
					$fnc >> "$LOG_OUTPUT_DRV_FILE" 2>&1
				fi
			fi
		done
	done

}

#
# Restituisce in output il nome del driver callback function da richiamare per una specifica funzione
#
# $1 nome della funzione per il quale si vuore recuperare la callback
# $2 idetificativo del driver
function get_driver_callback {
	local fnc="$1"
	local idx="$2"
	local ret=""

	if [[ "$idx" == drv:* ]]; then
		local drv=`echo $idx | $CUT -d':' -f2,2`
		if [[ ! " ${list_drv[@]} " =~ " ${drv} " ]]; then
			ret="drvnotfound"
		else
			ret="drv_${drv}_${fnc}"
		fi
	fi
	echo "$ret"
}

#
# Inizializza un relè e lo porta nello stato aperto
#
# $1	identificativo relè da inizializzare
#
function drv_rele_init {
	local idx="$1"
	local fnc=`get_driver_callback "rele_init" "$idx"`

	# Nessun driver definito, esegue la chiusura del relè tramite gpio del raspberry
	if [ -z "$fnc" ]; then
                $GPIO -g write $idx $RELE_GPIO_OPEN   # chiude l'alimentazione all'elettrovalvole
                $GPIO -g mode $idx out                # setta il gpio nella modalita di scrittura
	# Il driver definito non è stato trovato
	elif [ "$fnc" == "drvnotfound" ]; then
	        log_write "Driver not found: $idx"
        	message_write "warning" "Driver not found: $idx"
	else
		echo "$(date) $fnc arg:$idx" >> "$LOG_OUTPUT_DRV_FILE"
		$fnc "$idx" >> "$LOG_OUTPUT_DRV_FILE" 2>&1
	fi
}

#
# Chiude un relè
#
# $1	identificativo relè da chiudere
#
function drv_rele_close {
	local idx="$1"
	local fnc=`get_driver_callback "rele_close" "$idx"`

	# Nessun driver definito, esegue la chiusura del relè tramite gpio del raspberry
	if [ -z "$fnc" ]; then
		$GPIO -g write $idx $RELE_GPIO_CLOSE	
	# Il driver definito non è stato trovato
	elif [ "$fnc" == "drvnotfound" ]; then
	        log_write "Driver not found: $idx"
        	message_write "warning" "Driver not found: $idx"
		return 1
	else
		echo "$(date) $fnc arg:$idx" >> "$LOG_OUTPUT_DRV_FILE"
		$fnc "$idx" >> "$LOG_OUTPUT_DRV_FILE" 2>&1
		if [ $? -eq 1 ]; then
			return 1
		fi
	fi
}

#
# Apre un relè
#
# $1	identificativo relè da aprire
#
function drv_rele_open {
	local idx="$1"
	local fnc=`get_driver_callback "rele_open" "$idx"`

	# Nessun driver definito, esegue la chiusura del relè tramite gpio del raspberry
	if [ -z "$fnc" ]; then
		$GPIO -g write $idx $RELE_GPIO_OPEN	
	# Il driver definito non è stato trovato
	elif [ "$fnc" == "drvnotfound" ]; then
	        log_write "Driver not found: $idx"
        	message_write "warning" "Driver not found: $idx"
		return 1
	else
		echo "$(date) $fnc arg:$idx" >> "$LOG_OUTPUT_DRV_FILE"
		$fnc "$idx" >> "$LOG_OUTPUT_DRV_FILE" 2>&1
		if [ $? -eq 1 ]; then
			return 1
		fi
	fi
}

#
# Inizializza i rele che gestiscono l'alimentazione per le valvole bistabili
#
# $1	identificativo relè 1
# $2	identificativo relè 2
#
function drv_supply_bistable_init {
	local idx1=$1
	local idx2=$2
	local fnc1=`get_driver_callback "supply_bistable_init" "$idx1"`
	local fnc2=`get_driver_callback "supply_bistable_init" "$idx2"`

	# Nessun driver definito, esegue l'operazione tramite gpio del raspberry
	if [ -z "$fnc1" ]; then
		$GPIO -g write $idx1 0
		$GPIO -g mode $idx1 out
	# Il driver definito non è stato trovato
	elif [ "$fnc1" == "drvnotfound" ]; then
	        log_write "Driver not found: $idx1"
        	message_write "warning" "Driver not found: $idx1"
		return
	else
		echo "$(date) $fnc1 arg:$idx1" >> "$LOG_OUTPUT_DRV_FILE"
		$fnc1 "$idx1" >> "$LOG_OUTPUT_DRV_FILE" 2>&1
	fi

	# Nessun driver definito, esegue l'operazione tramite gpio del raspberry
	if [ -z "$fnc2" ]; then
		$GPIO -g write $idx2 0
		$GPIO -g mode $idx2 out
	# Il driver definito non è stato trovato
	elif [ "$fnc2" == "drvnotfound" ]; then
	        log_write "Driver not found: $idx2"
        	message_write "warning" "Driver not found: $idx2"
	else
		echo "$(date) $fnc2 arg:$idx2" >> "$LOG_OUTPUT_DRV_FILE"
		$fnc2 "$idx2" >> "$LOG_OUTPUT_DRV_FILE" 2>&1
	fi

}

#
# Imposta la tensine positiva per le elettrovalvole bistabili
#
# $1	identificativo rele 1
# $2	identificativo rele 2
#
function drv_supply_positive {
	local idx1=$1
	local idx2=$2
	local fnc1=`get_driver_callback "supply_positive" "$idx1"`
	local fnc2=`get_driver_callback "supply_positive" "$idx2"`

	# Nessun driver definito, esegue l'operazione tramite gpio del raspberry
	if [ -z "$fnc1" ]; then
		$GPIO -g write $idx1 $SUPPLY_GPIO_POS
	# Il driver definito non è stato trovato
	elif [ "$fnc1" == "drvnotfound" ]; then
	        log_write "Driver not found: $idx1"
        	message_write "warning" "Driver not found: $idx1"
		return
	else
		echo "$(date) $fnc1 arg:$idx1" >> "$LOG_OUTPUT_DRV_FILE"
		$fnc1 "$idx1" >> "$LOG_OUTPUT_DRV_FILE" 2>&1
	fi

	# Nessun driver definito, esegue l'operazione tramite gpio del raspberry
	if [ -z "$fnc2" ]; then
		$GPIO -g write $idx2 $SUPPLY_GPIO_POS
	# Il driver definito non è stato trovato
	elif [ "$fnc2" == "drvnotfound" ]; then
	        log_write "Driver not found: $idx2"
        	message_write "warning" "Driver not found: $idx2"
	else
		echo "$(date) $fnc2 arg:$idx2" >> "$LOG_OUTPUT_DRV_FILE"
		$fnc2 "$idx2" >> "$LOG_OUTPUT_DRV_FILE" 2>&1
	fi

}

#
# Imposta la tensine neagativa per le elettrovalvole bistabili
#
# $1	identificativo rele 1
# $2	identificativo rele 2
#
function drv_supply_negative {
	local idx1=$1
	local idx2=$2
	local fnc1=`get_driver_callback "supply_negative" "$idx1"`
	local fnc2=`get_driver_callback "supply_negative" "$idx2"`

	# Nessun driver definito, esegue l'operazione tramite gpio del raspberry
	if [ -z "$fnc1" ]; then
		$GPIO -g write $idx1 $SUPPLY_GPIO_NEG
	# Il driver definito non è stato trovato
	elif [ "$fnc1" == "drvnotfound" ]; then
	        log_write "Driver not found: $idx1"
        	message_write "warning" "Driver not found: $idx1"
		return
	else
		echo "$(date) $fnc1 arg:$idx1" >> "$LOG_OUTPUT_DRV_FILE"
		$fnc1 "$idx1" >> "$LOG_OUTPUT_DRV_FILE" 2>&1
	fi

	# Nessun driver definito, esegue l'operazione tramite gpio del raspberry
	if [ -z "$fnc2" ]; then
		$GPIO -g write $idx2 $SUPPLY_GPIO_NEG
	# Il driver definito non è stato trovato
	elif [ "$fnc2" == "drvnotfound" ]; then
	        log_write "Driver not found: $idx2"
        	message_write "warning" "Driver not found: $idx2"
	else
		echo "$(date) $fnc2 arg:$idx2" >> "$LOG_OUTPUT_DRV_FILE"
		$fnc2 "$idx2" >> "$LOG_OUTPUT_DRV_FILE" 2>&1
	fi

}

#
# Inizializza il sensore della pioggia
#
# $1	identificativo gpio sensore pioggia
#
function drv_rain_sensor_init {
	local idx="$1"
	local fnc=`get_driver_callback "rain_sensor_init" "$idx"`
	local vret=""

	# Nessun driver definito, esegue la lettura del sensore tramite gpio del raspberry
	if [ -z "$fnc" ]; then
		$GPIO -g mode $idx in
	# Il driver definito non è stato trovato
	elif [ "$fnc" == "drvnotfound" ]; then
	        log_write "Driver not found: $idx"
        	message_write "warning" "Driver not found: $idx"
	else
		echo "$(date) $fnc arg:$idx" >> "$LOG_OUTPUT_DRV_FILE"
		$fnc "$idx" >> "$LOG_OUTPUT_DRV_FILE" 2>&1
	fi

}

#
# Legge lo stato del sensore della pioggia
#
# $1	identificativo gpio sensore pioggia
#
function drv_rain_sensor_get {
	local idx="$1"
	local fnc=`get_driver_callback "rain_sensor_get" "$idx"`
	local vret=""

	# Nessun driver definito, esegue la lettura del sensore tramite gpio del raspberry
	if [ -z "$fnc" ]; then
		vret=`$GPIO -g read $idx`
	# Il driver definito non è stato trovato
	elif [ "$fnc" == "drvnotfound" ]; then
	        log_write "Driver not found: $idx"
        	message_write "warning" "Driver not found: $idx"
	else
		echo "$(date) $fnc arg:$idx" >> "$LOG_OUTPUT_DRV_FILE"
		vret=`$fnc "$idx"`
	fi

	echo "$vret"

}

#
# Legge lo stato le condizioni meteo dal servizio online
#
# $1	identificativo gpio sensore pioggia
#
function drv_rain_online_get {
	local idx="$1"
	local fnc=`get_driver_callback "rain_online_get" "$idx"`
	local vret=""

	# Nessun driver definito, esegue la lettura del sensore tramite gpio del raspberry
	if [ -z "$fnc" ]; then
	        log_write "Driver not found: $idx"
        	message_write "warning" "Driver not found: $idx"
	# Il driver definito non è stato trovato
	elif [ "$fnc" == "drvnotfound" ]; then
	        log_write "Driver not found: $idx"
        	message_write "warning" "Driver not found: $idx"
	else
		echo "$(date) $fnc arg:$idx" >> "$LOG_OUTPUT_DRV_FILE"
		vret=`$fnc "$idx"`
	fi

	echo "$vret"

}
