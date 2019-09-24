#
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file README.md
# Version: 0.2.30
# Data: 21/Sep/2019


FILE DI CONFIGURAZIONE /etc/piGarden.conf:
-----------------------------------------
NOTA: vedere nella directory conf_example il file esempio piu' aggiornato!

per attivare il driver e' necessario inserire la seguente variabile nel file di configurazion
	RAIN_GPIO="drv:rainsensorqty:25"        # Physical 22 - wPi 6

la variabile seguente e' impiegata anche da drv_rainsensorqty per rilevare la chiusura del contatto magnetico che, in un circuito pull-up, e' lo stato 1.
	# Valore in ingresso sul gpio definito in RAIN_GPIO che indica lo stato di pioggia
	RAIN_GPIO_STATE=1
le seguenti variabili controllano il driver come descritto:
	RAINSENSORQTY_LOOPSFORSETRAINING=16 # dopo 16 impulsi, 16 vaschette riempite si considera pioggia
	RAINSENSORQTY_SECSBETWEENRAINEVENT=10800 # =3h, significa che dopo 3 si resetta il numero di vaschette da riempire e solo dopo il riempimento del nuovo numero di vaschette si considera una nuova pioggia
infine la variabile seguente e' la quantita' di acqua espressa in mm di precipitazioni:
	RAINSENSORQTY_MMEACH=0.33 # see RAINSENSORQTY driver readme for details

CALIBRAZIONE SENSORE PIOGGIA
----------------------------
secondo il seguente processo da me effettuato sul mio misuratore di pioggia:
Ho erogato 18 ml di acqua nel rain gauge che hanno prodotto 10 impulsi; pertanto il riempimento di 1.8 ml ha causato un impulso, 1 ml = 1000 mmc (mm cubici),
1.8 ml sono pari a 1800 mmc
la superficie della vaschetta in mmq e' pari a 110 mm x 55 mm = 5500 mmq
volume / superficie mi da' l'altezza, quindi 1800 mmc / 5500 mmq = 0.32727273 mm
se fossero stati 1.7 ml di acqua per ogni impulso/vaschetta riempita, la variabile sarebbe stata impostata a 0.30909091 mm

COMANDI SPECIALI
----------------
nella sottodirectory command sono presenti:
commands/rainsensorqty_CHECK.sh
	chiama la funzione di verifica pioggia, la medesima chiamata da check_rain_sensor
commands/rainsensorqty_HISTORY.sh
	visualizza lo storico della pioggia
commands/rainsensorqty_INIT.sh
	inizializza il driver eseguendo lo script di monitoring - normalmente tale processo avviene da piGarden.sh
	utile quando si vuole testare dei cambiamenti o se necessario riavviare dopo il kill del comando successivo
commands/rainsensorqty_KILL.sh
	killa i processi di monitoring ed eventuali figli
commands/rainsensorqty_RAINNOW.sh
	simula una pioggia registrandola in $RAINSENSORQTY_LASTRAIN
commands/rainsensorqty_REMOVELASTRAIN.sh
	rimuove dai file $RAINSENSORQTY_LASTRAIN $RAINSENSORQTY_HISTORY l'ultima pioggia registrata
commands/rainsensorqty_RESET.sh
	invia il SIGUSR1 al processo di monitor per resettare i cicli. Viene visualizzato il reset solo dopo il successivo PULSE, questo perche' non e' possibile per lo script ricevere il trap in quanto il processo $GPIO e' attivo in attesa del PULSE


ULTERIORI VARIABILI in config.include.sh
----------------------------------------
esistono ulteriori variabili che potrebbe essere necessario variare

RAINSENSOR_DEBOUNCE=0.3 # 0.3 seconds for manage debounce of reed contact
	serve per ritardare la lettura di un secondo impulso falso causato dal rimbalzo del contatto magnetico

RAINSENSORQTY_verbose="yes"
	aumenta il livello di verbosita' nei file di log
	
RAINSENSORQTY_LASTRAIN="$STATUS_DIR/rainsensorqty_lastrain"
	memorizza l'ultima pioggia
RAINSENSORQTY_HISTORY="$STATUS_DIR/rainsensorqty_history"
	memorizza tutte le piogge permettendo di visualizzare lo storico (commands/rainsensorqty_HISTORY.sh)

RAINSENSORQTY_MONITORLOG="$DIR_SCRIPT/log/rainsensorqty_monitor.log"
	log dello script di monitoring, popolato solo se RAINSENSORQTY_verbose="yes"

RAINSENSORQTY_MONPID="$TMPDIR/rainsensorqty_monitor.pid"
	file che viene popolato con il pid dello script di monitoring
RAINSENSORQTY_STATE="$TMPDIR/rainsensorqty_state"
	file che viene popolato con l'ultimo stato della vaschetta (formato timestamp:counter)

RAINSENSORQTY_DIR="$DIR_SCRIPT/drv/rainsensorqty"
	home directory del driver

monitor_sh="$RAINSENSORQTY_DIR/drv_rainsensorqty_monitor.sh"
	script di monitoring
	lo script eredita le variabili di ambiente da $RAINSENSORQTY_VAR ($TMPDIR/.rainsensorqty_var)

NOTA: $TMPDIR e' /tmp e lo script visualizza un warning se non e' un tmpfs

# internal gpio resistor, 3 values: pull-up, pull-down, none
# pull-up/down if rain gauge is connected directly to raspberry
# none if connected through an optocoupler circuit
GPIO_RESISTOR="none" #pull-up|pull-down|none
	enable pull-up or pull-down resistor: https://raspberry-projects.com/pi/pi-hardware/raspberry-pi-model-b-plus/model-b-plus-io-pins
	Pull-up is 50K min - 65K max.
	Pull-down is 50K min - 60K max. 

#rising means waiting for 1 status (from 0)
#falling means waiting for 0 status (from 1)
#RAINSENSORQTY_PULSE=rising  # pull-down circuit (rest status is 0)
#RAINSENSORQTY_PULSE=falling # pull-up circuit   (rest status is 1)
(( RAIN_GPIO_STATE == 1 )) && RAINSENSORQTY_PULSE=rising  # pull-down circuit (rest status is 0)
(( RAIN_GPIO_STATE == 0 )) && RAINSENSORQTY_PULSE=falling # pull-up circuit   (rest status is 1)

	lo script di monitoring ascolta il cambiamento di stato da quello di riposo allo stato di impulso (chiusura del contatto reed).
	dipendentemente dal circuto implementato, se lo stato di riposo e' 0, lo script attende la variazione verso 1 (rising)
	se lo stato di riposo e' 1, lo script attende la variazione verso 0 (falling)
	la variabile RAINSENSORQTY_PULSE viene impostata secondo il valore di RAIN_GPIO_STATE presente in /etc/piGarden.conf
	cioe' il valore che ci si aspetta per registrare il riempimento della vaschetta dello stato di pioggia


