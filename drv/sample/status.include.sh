#
# Questa funzione viene richiamata da "ev_get_status" di piGarden 
#
# $1 identificativo relè di cui repereire lo stato 
#
function drv_sample_status {

	echo "$(date) drv_sample_status $1" >> /tmp/piGarden.drv.sample

}

