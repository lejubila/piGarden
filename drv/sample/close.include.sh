#
# Questa funzione viene richiamata da "ev_close" di piGarden 
#
# $1 identificativo relè da chiudere
#
function drv_sample_close {

	echo "$(date) drv_sample_close $1" >> /tmp/piGarden.drv.sample

}

