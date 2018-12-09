#
# Inizializza il driver, viene richiamata nella funzione init di piGarden
#
# variables from general config file /etc/piGarden.conf
#RAINSENSORQTY_LOOPSFORSETRAINING=10 # dopo 10 impulsi, 10 vaschette riempite si considera pioggia
#RAINSENSORQTY_SECSBETWEENRAINEVENT=10800 # =3h, significa che dopo 3 si resetta il numero di vaschette da riempire e solo dopo il riempimento del numero di vaschette si considera una nuova pioggia

function drv_rainsensorqty_init {
	local f="drv_rainsensorqty_init"
        local monitor_sh="$RAINSENSORQTY_DIR/rainsensorqty_monitor.sh"

	# format RAIN_GPIO="drv:rainsensorqty:25" 

	drv_rainsensorqty_writelog $f "NORMAL - executing $monitor_sh"

	# esegue rainmonitor 
	if [ -x "$monitor_sh" ] ; then
       		nohup "$monitor_sh" >> $RAINSENSORQTY_MONITORLOG 2>&1 &
               	sleep 1
		drv_rainsensorqty_writelog $f "NORMAL: $monitor_sh has pid $( < $RAINSENSORQTY_MONPID)"
	else 
		drv_rainsensorqty_writelog $f "ERROR: cannot find \"\$monitor_sh \" "
	fi

}

set | $GREP -e ^GPIO -e ^LOG -e ^CUT -e ^JQ -e ^RAIN -e ^SCR -e ^TMP > "$RAINSENSORQTY_DIR/set_var"

