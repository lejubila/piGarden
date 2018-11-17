#
# Inizializza il sensore di rilevamento pioggia 
#
# $1 	identificativo gpio del sensore di pioggia
#
function drv_rainsensorqty_rain_sensor_init {

	echo "drv_rainsensorqty_rain_sensor_init $1" >> "$LOG_OUTPUT_DRV_FILE"

	local drvt="$( echo $RAIN_GPIO | $CUT -f 1 -d: )"
	local drv="$( echo $RAIN_GPIO | $CUT -f 2 -d: )"
	local gpio="$( echo $RAIN_GPIO | $CUT -f 3 -d: )"

	$GPIO -g mode $gpio in

}

#
# Ritorna in output lo stato del sensore di rilevamento pioggia 
#
# $1 	identificativo gpio del sensore di pioggia
#
function drv_rainsensorqty_rain_sensor_get {

	echo "drv_rainsensorqty_rain_sensor_get $1" >> "$LOG_OUTPUT_DRV_FILE"

	if [ drv_rainsensorqty_check ]; then
		# Cosa deve fare ???? 
		# gli facciamo rieseguire drv_rainsensorqty_init in modo che riavvii il monitor ???
	fi	


	local state_rain=""

	# INSERISCI QUI DENTRO I CONTROLLI SUL FILE $STATUS_DIR/rainsensorqty_lastrain
	# SE SI VERIFICANO LE CONDIZIONI PER CUI SI DEVE INTERROMPERE L'IRRIGAZIONE
	# DEVI IMPOSTARE last_rain CON IL VALORE $RAIN_GPIO_STATE

	#
	#
	#
	#
	#
	#
	#
	#
	#
	#

	echo $state_rain

}


