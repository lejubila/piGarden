#
# Inizializza i rele che gestiscono l'alimentazione per le valvole bistabili
#
# $1    identificativo relè 1
# $2    identificativo relè 2
#
function drv_sample_supply_bistable_init {

	echo "$(date) drv_sample_supply_bistable_init $1 $2" >> /tmp/piGarden.drv.sample
}

#
# Imposta l'alimentazione delle elettrovalvole con voltaggio positivo 
#
# $1    identificativo relè 1
# $2    identificativo relè 2
#
function drv_sample_supply_positive {

	echo "$(date) drv_sample_supply_positive $1 $2" >> /tmp/piGarden.drv.sample

}

#
# Imposta l'alimentazione delle elettrovalvole con voltaggio negativo
#
# $1    identificativo relè 1
# $2    identificativo relè 2
#
function drv_sample_supply_negative {

	echo "$(date) drv_sample_supply_negative $1 $2" >> /tmp/piGarden.drv.sample

}


