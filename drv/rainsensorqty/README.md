#
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file README.md
# Version: 0.2.0
# Data: 11/Aug/2019


FILE DI CONFIGURAZIONE /etc/piGarden.conf:
-----------------------------------------
NOTA: vedere nella directory conf_example il file esempio piu' aggiornato!

per attivare il driver è necessario inserire la seguente variabile nel file di configurazion
	RAIN_GPIO="drv:rainsensorqty:25"        # Physical 22 - wPi 6

la variabile seguente è impiegata anche da drvrainsensorqty per rilevare la chiusura del contatto magnetico che, in un circuito pull-up, è lo stato 1.
	# Valore in ingresso sul gpio definito in RAIN_GPIO che indica lo stato di pioggia
	RAIN_GPIO_STATE=1
le seguenti variabili controllano il driver come descritto:
	RAINSENSORQTY_LOOPSFORSETRAINING=16 # dopo 10 impulsi, 10 vaschette riempite si considera pioggia
	RAINSENSORQTY_SECSBETWEENRAINEVENT=10800 # =3h, significa che dopo 3 si resetta il numero di vaschette da riempire e solo dopo il riempimento del numero di vaschette si considera una nuova pioggia
infine la variabile seguente è la quantita' di acqua espressa in mm di precipitazioni:
	RAINSENSORQTY_MMEACH=0.33 # see RAINSENSORQTY driver readme for details

CALIBRAZIONE SENSORE PIOGGIA
----------------------------
secondo il seguente processo da me effettuato sul mio misuratore di pioggia:
Ho erogato 18 ml di acqua nel rain gauge che hanno prodotto 10 impulsi; pertanto il riempimento di 1.8 ml ha causato un impulso, 1 ml = 1000 mmc (mm cubici),
1.8 ml sono pari a 1800 mmc
la superficie della vaschetta in mmq è pari a 110 mm x 55 mm = 5500 mmq
volume / superficie mi da' l'altezza, quindi 1800 mmc / 5500 mmq = 0.32727273 mm
se fossero stati 1.7 ml di acqua per ogni impulso/vaschetta riempita, la varibile sarebbe stata impostata a 0.30909091 mm

COMANDI SPECIALI
----------------
nella sottidirectory command sono prensenti:
commands/rainsensorqty_CHECK.sh
	chiama la funzione di verifica piggio, la medesima chiamata da check_rain_sensor
commands/rainsensorqty_HISTORY.sh
	visualizza lo storico della pioggia
commands/rainsensorqty_INIT.sh
	inizializza il driver eseguendo lo script di monitoring - normalmente tale processo avviene da piGarden.sh
	utile quando si vuole testare dei cambiamenti o se necessario riavviare dopo il kill del comando successivo
commands/rainsensorqty_KILL.sh
	killa i processi di monitoring ed eventuali figli
commands/rainsensorqty_RAINNOW.sh
	simula una pioggia

ULTERIORI VARIABILI in config.include.sh
----------------------------------------
esistono ulteriori variabili che potrebbe essere necessario variare

RAINSENSOR_ANTIBOUNCE=0.3 # 0.3 seconds for manage antibounce of reed contact
	server per ritardare la lettura di un secondo impulso falso causato dal rimbalzo del contatto magnetico

RAINSENSORQTY_verbose="yes"
	aumenta il livello di verbosita' nei file di log
	
RAINSENSORQTY_LASTRAIN="$STATUS_DIR/rainsensorqty_lastrain"
	memorizza l'ultima pioggia
RAINSENSORQTY_HISTORY="$STATUS_DIR/rainsensorqty_history"
	memorizza tutte le piogge permettendo di visualizzarlo storico (commands/rainsensorqty_HISTORY.sh)

RAINSENSORQTY_MONITORLOG="$DIR_SCRIPT/log/rainsensorqty_monitor.log"
	log del script di monitoring, popolato solo se RAINSENSORQTY_verbose="yes"

RAINSENSORQTY_MONPID="$TMP_PATH/rainsensorqty_monitor.pid"
	file che viene popolato con il pid dello script di monitoring

RAINSENSORQTY_DIR="$DIR_SCRIPT/drv/rainsensorqty"
	home directory del driver

monitor_sh="$RAINSENSORQTY_DIR/drv_rainsensorqty_monitor.sh"
	script di monitoring
	lo script eredita le varibili di ambiente da .set_var in $RAINSENSORQTY_DIR

#rising means waiting for 1 status (from 0)
#falling means waiting for 0 status (from 1)
#RAINSENSORQTY_PULSE=rising  # pull-down circuit (rest status is 0)
#RAINSENSORQTY_PULSE=falling # pull-up circuit   (rest status is 1)
if (( RAIN_GPIO_STATE = 1 )) ; then
        RAINSENSORQTY_PULSE=rising  # pull-down circuit (rest status is 0)
fi
if (( RAIN_GPIO_STATE = 0 )) ; then
        RAINSENSORQTY_PULSE=falling # pull-up circuit   (rest status is 1)
fi
if [[ -z $RAINSENSORQTY_PULSE ]] ; then
         echo "ERROR: RAIN_GPIO_STATE non set in piGarden.conf"
         exit 1
fi

	lo script di monitoring ascolta il cambiamento di stato da quello di riposo allo stato di impulso (chiusura del contatto reed).
	dipendentemente dal circuto implementato, se lo stato di riposo e' 0, lo script attende la variazione verso 1 (rising)
	se lo stato di riposo e' 1, lo script attende la variazione verso 0 (falling)
	la variabile RAINSENSORQTY_PULSE viene impostata secondo il valore di RAIN_GPIO_STATE presente in /etc/piGarden.conf
	cioe' il valore che ci si aspetta per registrare lo stato di pioggia


