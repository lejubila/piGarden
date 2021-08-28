#
# Imposta lo stato di una elettrovalvola
# $1 numero del sensore
# $2 tipologia dello stato
# $3 stato da scrivere
#
function sensor_set_state {
	trigger_event "sensor_set_state_before" $1 $2 $3
	echo "$3" > "$STATUS_DIR/sensor$1_$2"
	trigger_event "sensor_set_state_after" $1 $2 $3
}

#
# Legge lo stato di un sensore
# $1 numero del sensore
# $2 tipologia dello stato
#
function sensor_get_state {
	if [ ! -f "$STATUS_DIR/sensor$1_$2" ]; then
		sensor_set_state $1 $2 ""
	fi

	local state=$(cat "$STATUS_DIR/sensor$1_$2" 2> /dev/null)
	echo $state
}

#
# Recupera il numero di un sensore in base all'alias
# $1 alias del sensore
#
function sensor_alias2number {
	for i in $(seq $EV_TOTAL)
	do
		a=SENSOR"$i"_ALIAS
		av=${!a}
		if [ "$av" == "$1" ]; then
			return $i
		fi
	done

	log_write "general" "error" "ERROR sensor alias not found: $1"
	message_write "warning" "Sensor alias not found"
	mqtt_status
	exit 1
}

#
# Verifica se un alias di un sensore esiste
# $1 alias dell'elettrovalvola
#
function sensor_alias_exists {
	local vret='FALSE'
	for i in $(seq $EV_TOTAL)
	do
		a=SENSOR"$i"_ALIAS
		av=${!a}
		if [ "$av" == "$1" ]; then
			vret='TRUE'
		fi
	done

	echo $vret
}

#
# Mostra lo stato di tutte le elettrovalvole
#
function sensor_status_all {
	for i in $(seq $SENSOR_TOTAL)
	do
		a=SENSOR"$i"_ALIAS
		av=${!a}
		for t in $SENSOR_STATE_TYPE
		do
			local state=$(sensor_get_state $i $t)
			echo -e "$av: $t $state"
		done
	done
}

#
# Mostra lo stato di un sensore
# $1 alias sensore
# $2 tipologia dello stato
#
function sensor_status {
	sensor_alias2number $1
	i=$?
	if [ -z "$2" ]; then
		for t in $SENSOR_STATE_TYPE
		do
			local state=$(sensor_get_state $i $t)
			echo -e "$av: $t $state"
		done
	else
		local state=$(sensor_get_state $i $2)
		echo -e "$state"
	fi

}

#
# Imposta lo stato di un sensore per alias
# $1 alias sensore
# $2 tipologia dello stato
# $3 stato da imopostare
#
function sensor_status_set {
	sensor_alias2number $1
	i=$?
	sensor_set_state $i $2 $3
	mqtt_status
}

#
# Stampa la lista degli alias dei sensori
#
function list_alias_sensor {

	for i in $(seq $SENSOR_TOTAL)
	do
		local a=SENSOR"$i"_ALIAS
		local al=${!a}
		echo $al
	done

}

#
# Stampa lo stato di tutti i sensori in formato json
#
function json_sensor_status_all {
	local js=""
	local js_item=""
	local js_type=""

	for i in $(seq $SENSOR_TOTAL)
	do
		a=SENSOR"$i"_ALIAS
		av=${!a}

		js_type=""
		for t in $SENSOR_STATE_TYPE
		do
			local state=$(sensor_get_state $i $t)
			js_type="$js_type \"$t\": \"$state\", "
		done
		js_type="${js_type::-2}"
		js_item="$js_item \"$av\":{$js_type}, ";
	done

	if [[ ! -z $js_item ]]; then
		js_item="${js_item::-2}"
	fi

	js="\"sensor\": {$js_item}"
	echo $js
}

#
# Controlla se la zona comandata da un elettrovalvola ha raggiunto l'umidità necessaria per non fare partire l'irrigazione,
# faerla chiudere in caso di pioggia.
# Se è stata superata l'umidità indicata in EVx_SENSOR_MOISTURE ritorna l'umidità attuale del sensore relativo all'elettrovalvola
# in caso contrario ritorna 0, se no è impostato il parametro EV_xSENSOR_ALIAS o EVxSENSOR?MOISTURE ritorna il valore -1
#
# $1 numero elettrovalvola da controllare
#
function ev_check_moisture {

	local s=EV"$1"_SENSOR_ALIAS
	local sa=${!s}

	if [[ -z $sa ]]; then
		echo -1
		return
	fi

	local moisture=$(sensor_status $sa moisture)

	local s=EV"$1"_SENSOR_MOISTURE
	local max_moisture=${!s}

	if [ -z $max_moisture ]; then
		echo -1
		return
	fi

	if [ $moisture -gt $max_moisture ]; then
		log_write "sensor" "info" "ev_check_moisture_autoclose: humidity of the \"$sa\" sensor reached: $moisture%"
		echo $moisture
		return $moisture
	fi

	echo 0
	return 0
}

#
# Controlla se la zona comandata da un elettrovalvola ha raggiunto l'umidità necessaria per essere chiusa in automatico
# Se è stata superata l'umidità indicata in EVx_SENSOR_MOISTURE ritorna l'umidità attuale del sensore relativo all'elettrovalvola
# in caso contrario ritorna 0, se no è impostato il parametro EV_xSENSOR_ALIAS, EVxSENSOR_MOISTURE o 
# EVxSENSOR_MOISTURE_AUTOCLOSE ritorna il valore -1
#
# $1 numero elettrovalvola da controllare
#
function ev_check_moisture_autoclose {

	local s=EV"$1"_SENSOR_ALIAS
	local sa=${!s}

	if [[ -z $sa ]]; then
		echo -1
		return
	fi

	local moisture=$(sensor_status $sa moisture)

	local s=EV"$1"_SENSOR_MOISTURE
	local max_moisture=${!s}

	if [ -z $max_moisture ]; then
		echo -1
		return
	fi

	local s=EV"$1"_SENSOR_MOISTURE_AUTOCLOSE
	local autoclose=${!s}

	if [ -z $autoclose ]; then
		echo -1
		return
	fi

	if [ $autoclose -ne 1 ]; then
		echo -1
		return
	fi

	if [ $moisture -gt $max_moisture ]; then
		log_write "sensor" "info" "ev_check_moisture_autoclose: humidity of the \"$sa\" sensor reached: $moisture%"
		echo $moisture
		return $moisture
	fi

	echo 0
	return 0
}


