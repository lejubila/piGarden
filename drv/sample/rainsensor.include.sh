#
# Inizializza il sensore di rilevamento pioggia 
#
# $i 	identificativo gpio del sensore di pioggia
#
function drv_sample_rain_sensor_init {

	echo "$(date) drv_sample_rain_sensor_init $1" >> /tmp/piGarden.drv.sample

}

#
# Ritorna lo stato del sensore di rilevamento pioggia 
#
# $i 	identificativo gpio del sensore di pioggia
#
function drv_sample_rain_sensor_get {

	echo "$(date) drv_sample_rain_sensor_get $1" >> /tmp/piGarden.drv.sample

}


