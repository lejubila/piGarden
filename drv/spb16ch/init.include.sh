#
# Questa funzione viene inviocata dalla funzione "init" di piGarden se sono presenti elettrovalvole o sensori che utilizzano questo driver
#
function drv_spb16ch_init {

	$DIR_SCRIPT/drv/spb16ch/scripts/mux_channel.py 72 0
	$DIR_SCRIPT/drv/spb16ch/scripts/gpo_init.py 25 255 0
	$DIR_SCRIPT/drv/spb16ch/scripts/mux_channel.py 72 1
	$DIR_SCRIPT/drv/spb16ch/scripts/gpo_init.py 25 255 0
	$DIR_SCRIPT/drv/spb16ch/scripts/mux_channel.py 72 0

}

