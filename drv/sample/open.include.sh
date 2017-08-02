#
# Questa funzione viene richiamata da "ev_open" di piGarden 
#
# $1 identificativo relè da aprire 
#
function drv_sample_open {

	echo "$(date) drv_sample_open $1" >> /tmp/piGarden.drv.sample

}

