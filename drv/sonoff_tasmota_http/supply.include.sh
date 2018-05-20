#
# Inizializza i rele che gestiscono l'alimentazione per le valvole bistabili
#
# $1    identificativo relè 
#
function drv_sonoff_tasmota_http_supply_bistable_init {

	drv_sonoff_tasmota_http_supply_negative "$1"

}

#
# Imposta l'alimentazione delle elettrovalvole con voltaggio positivo 
#
# $1    identificativo relè 
#
function drv_sonoff_tasmota_http_supply_positive {

	drv_sonoff_tasmota_http_rele_open "$1"

}

#
# Imposta l'alimentazione delle elettrovalvole con voltaggio negativo
#
# $1    identificativo relè 
#
function drv_sonoff_tasmota_http_supply_negative {

	drv_sonoff_tasmota_http_rele_close "$1"

}


