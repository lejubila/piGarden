#
# Questa funzione viene inviocata dalla funzione "init" di piGarden se sono presenti elettrovalvole o sensori che utilizzano questo driver
#
function drv_sample_init {

	echo "$(date) drv_sample_init" >> /tmp/piGarden.drv.sample

}

