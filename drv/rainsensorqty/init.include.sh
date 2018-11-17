#
# Inizializza il driver, viene richiamata nella funzione init di piGarden
#
# variables from general config file /etc/piGarden.conf
#RAINSENSORQTY_LOOPSFORSETRAINING=10 # dopo 10 impulsi, 10 vaschette riempite si considera pioggia
#RAINSENSORQTY_SECSBETWEENRAINEVENT=10800 # =3h, significa che dopo 3 si resetta il numero di vaschette da riempire e solo dopo il riempimento del numero di vaschette si considera una nuova pioggia

function drv_rainsensorqty_init {
	# format RAIN_GPIO="drv:rainsensorqty:25" 

	# esegue rainmonitor 
	if [[ -x "$monitor_sh" ]] ; then
		echo "OK - run rainmonitor"
		nohup "$monitor_sh" $gpio $RAINSENSORQTY_LOOPSFORSETRAINING $RAINSENSORQTY_SECSBETWEENRAINEVENT >> /tmp/debug_rainmonitor.log 2>&1 &
                sleep 1
	else
		:
		echo "KO - not run rainmonitor"
        fi


}

