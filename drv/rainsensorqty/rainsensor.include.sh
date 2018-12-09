#
# Inizializza il sensore di rilevamento pioggia 
#
# $1 	identificativo gpio del sensore di pioggia
#
function drv_rainsensorqty_rain_sensor_init {
	drv_rainsensorqty_writelog "drv_rainsensorqty_rain_sensor_init" $1 

	local drvt="$( echo $RAIN_GPIO | $CUT -f 1 -d: )"
	local drv="$( echo $RAIN_GPIO | $CUT -f 2 -d: )"
	local gpio_port="$( echo $RAIN_GPIO | $CUT -f 3 -d: )"

	$GPIO -g mode $gpio_port in

}

#
# Ritorna in output lo stato del sensore di rilevamento pioggia 
#
# $1 	identificativo gpio del sensore di pioggia
#
function drv_rainsensorqty_rain_sensor_get {
	local now=$(date +%s)
	local interval=100 # 100 secondi > 1 minuto frequenza di verifica da parte di, come da seguente schedulazione 
	#* * * * * /home/pi/piGarden/piGarden.sh check_rain_sensor 2> /tmp/check_rain_sensor.err
 	local f="drv_rainsensorqty_check"
 	drv_rainsensorqty_writelog $f $1

	# verifica se lo script di monitorin e' attivo
	if drv_rainsensorqty_check ; then
 		drv_rainsensorqty_writelog $f "NORMAL - drv_rainsensorqty_check ok, monitor process running"
		if [ -f "$RAINSENSORQTY_LASTRAIN" ] ; then
			local lastrain="$( < "$RAINSENSORQTY_LASTRAIN" )"
		        (( diff = now - lastrain ))
			drv_rainsensorqty_writelog $f "NORMAL: last rain $( date --date="@$lastrain"  ) "
			drv_rainsensorqty_writelog $f "NORMAL: check rain $( date --date="@$now"  ) "
			if (( diff <= interval )) ; then
				drv_rainsensorqty_writelog $f "RAIN : check rain - diff $diff < $interval - return $RAIN_GPIO_STATE"
				return $RAIN_GPIO_STATE
			else 
				drv_rainsensorqty_writelog $f "NO_RAIN : check rain - diff $diff < $interval - return 99"
				return 99
			fi

		fi
	else
 		drv_rainsensorqty_writelog $f "ERROR - drv_rainsensorqty_check failed, no monitor process running"
		exit 1
		
	fi	


}
