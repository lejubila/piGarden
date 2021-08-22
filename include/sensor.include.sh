#
# Imposta lo stato di una elettrovalvola
# $1 numero del sensore
# $2 tipologia dello stato
# $3 stato da scrivere
#
function sensor_set_state {
	echo "$3" > "$STATUS_DIR/sensor$1_$2"
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

	return `cat "$STATUS_DIR/sensor$1_$2"`
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
			sensor_get_state $i $t
			echo -e "$av: $t $?"
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
			sensor_get_state $i $t
			echo -e "$av: $t $?"
		done
	else
		sensor_get_state $i $2
		local state=$?
		echo -e "$state"
		return $state
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
			sensor_get_state $i $t
			js_type="$js_type \"$t\": \"$?\", "
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
