#
# Driver rainsensorqty - driver for measure the rain volume, for rain meter, for rain gauge
# Author: androtto
# file "rainsensor.include.sh"
# functions called by piGarden.sh
# Version: 0.1.2
# Data: 19/Mar/2019
# fixed output drv_rainsensorqty_rain_sensor_get

#
# Inizializza il sensore di rilevamento pioggia 
#
# $1 	identificativo gpio del sensore di pioggia
#
drv_rainsensorqty_rain_sensor_init()
{
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
# restituisce 0 se piove, e nell'output di testo il valore di "$RAIN_GPIO_STATE"
# restituisce 99 se non piove, output "norain"
# esce con 1 se non c'e' il monitoring, output "ERROR"
drv_rainsensorqty_rain_sensor_get()
{
	local now=$(date +%s)
	local interval=60 #   because check_rain_sensor is scheduled once a minute ... to changed if schedule is modified, from crontab:
	#* * * * * /home/pi/piGarden/piGarden.sh check_rain_sensor 2> /tmp/check_rain_sensor.err

 	local f="drv_rainsensorqty_check"
	
	# script called with:	
	#drv_rainsensorqty_writelog $f $1
	# ignora il parametro di $1, lo recupera dal file di configurazione

	# verifica se lo script di monitoring e' attivo
	if drv_rainsensorqty_check ; then
 		drv_rainsensorqty_writelog $f "NORMAL - drv_rainsensorqty_check ok, monitor process running"
		if [ -f "$RAINSENSORQTY_LASTRAIN" ] ; then
			local lastrain="$( cat "$RAINSENSORQTY_LASTRAIN" | $CUT -f 1 -d: )"
			local counter="$( cat "$RAINSENSORQTY_LASTRAIN" | $CUT -f 2 -d: )"
		        LEVEL=$( $JQ -n "$counter/$RAINSENSORQTY_LOOPSFORSETRAINING" | $JQ 'floor' )
		        (( diff = now - lastrain ))
			drv_rainsensorqty_writelog $f "NORMAL: last rain $( date --date="@$lastrain"  ) - LEVEL $LEVEL rain"
			drv_rainsensorqty_writelog $f "NORMAL: check rain $( date --date="@$now"  ) "
			if (( diff <= interval )) ; then
				drv_rainsensorqty_writelog $f "RAIN - return \$RAIN_GPIO_STATE = $RAIN_GPIO_STATE as output"
				drv_rainsensorqty_writelog $f "DEBUG : check rain - diff $diff < $interval - return $RAIN_GPIO_STATE"
				msg="$RAIN_GPIO_STATE" 
				echo $msg
				return 0
			else 
				drv_rainsensorqty_writelog $f "NO_RAIN - return \"norain\" as output"
				drv_rainsensorqty_writelog $f "DEBUG : check rain - diff $diff < $interval - return 99"
				msg="norain"
				echo $msg
				return 99
			fi
		fi
	else
 		drv_rainsensorqty_writelog $f "ERROR: drv_rainsensorqty_check failed, no monitor process running ($monitor_sh)"
		msg="ERROR"
		echo $msg
		return 1
	fi	
}
