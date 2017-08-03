#
# Apertura rele 
#
# $1 identificativo relè da aprire 
#
function drv_sample_rele_open {

	echo "$(date) drv_sample_rele_open $1" >> /tmp/piGarden.drv.sample

}

#
# Chiusura rele 
#
# $1 identificativo relè da chiudere
#
function drv_sample_rele_close {

	echo "$(date) drv_sample_rele_close $1" >> /tmp/piGarden.drv.sample

}

