#
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "init.include.sh"
# Inizializza il driver, viene richiamata nella funzione init di piGarden
# Version: 0.2.0
# Data: 11/Aug/2019

function drv_rainsensorqty_init {
	local f="drv_rainsensorqty_init"

	# format RAIN_GPIO="drv:rainsensorqty:25" 

	drv_rainsensorqty_writelog $f "NORMAL: executing $monitor_sh"

	# esegue rainmonitor 
	if [ -x "$monitor_sh" ] ; then
       		nohup "$monitor_sh" >> $RAINSENSORQTY_MONITORLOG 2>&1 &
               	sleep 1
		drv_rainsensorqty_writelog $f "NORMAL: $monitor_sh has pid $( < $RAINSENSORQTY_MONPID)"
	else 
		drv_rainsensorqty_writelog $f "ERROR: cannot find \"\$monitor_sh \" "
	fi
}

set | $GREP -e ^GPIO -e ^LOG -e ^CUT -e ^JQ -e ^RAIN -e ^SCR -e ^TMP > "${RAINSENSORQTY_DIR}/.set_var"
