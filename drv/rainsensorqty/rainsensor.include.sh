#
# Inizializza il sensore di rilevamento pioggia 
#
# $1 	identificativo gpio del sensore di pioggia
#
function drv_rainsensorqty_rain_sensor_init {

	echo "drv_rainsensorqty_rain_sensor_init $1" >> "$LOG_OUTPUT_DRV_FILE"
	echo 0 > "$RAINSENSORQTY_FILE_RUN"

}

#
# Ritorna lo stato del sensore di rilevamento pioggia 
#
# $1 	identificativo gpio del sensore di pioggia
# return 	0 = pioggia
#
function drv_rainsensorqty_rain_sensor_get {

	echo "drv_rainsensorqty_rain_sensor_get $1" >> "$LOG_OUTPUT_DRV_FILE"

	local state_rain=""

	if [ $(cat "$RAINSENSORQTY_FILE_RUN") == 1 ]; then
		return
	else
		echo 1 > "$RAINSENSORQTY_FILE_RUN"
	fi

	# Inserisci qui il codice per il controllo della pioggia e imposta il valore 0 a state_rain quando se sta piovendo








	echo 0 > "$RAINSENSORQTY_FILE_RUN"

	return $state_rain

}


