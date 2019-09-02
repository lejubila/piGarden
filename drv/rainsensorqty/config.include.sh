#
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "config.include.sh"
# specific driver config file
# Version: 0.2.0
# Data: 11/Aug/2019

RAINSENSOR_DEBOUNCE=0.3 # 0.3 seconds for manage debounce of reed contact

RAINSENSORQTY_verbose="yes" # yes/no

RAINSENSORQTY_LASTRAIN="$STATUS_DIR/rainsensorqty_lastrain"
RAINSENSORQTY_HISTORY="$STATUS_DIR/rainsensorqty_history"

RAINSENSORQTY_MONITORLOG="$DIR_SCRIPT/log/rainsensorqty_monitor.log"

RAINSENSORQTY_MONPID="$TMP_PATH/rainsensorqty_monitor.pid"
RAINSENSORQTY_STATE="$TMP_PATH/rainsensorqty_state"
RAINSENSORQTY_STATE_HIST="$TMP_PATH/rainsensorqty_state.history"

RAINSENSORQTY_DIR="$DIR_SCRIPT/drv/rainsensorqty"

monitor_sh="$RAINSENSORQTY_DIR/drv_rainsensorqty_monitor.sh"

# internal gpio resistor, 3 values: pull-up, pull-down, none
# pull-up/down if rain gauge is connected directly to raspberry
# none if connected through an optocoupler circuit
GPIO_RESISTOR="pull-up" #pull-up|pull-down|none

#rising means waiting for 1 status (from 0)
#falling means waiting for 0 status (from 1)
#RAINSENSORQTY_PULSE=rising  # pull-down circuit (rest status is 0)
#RAINSENSORQTY_PULSE=falling # pull-up circuit   (rest status is 1)
(( RAIN_GPIO_STATE == 1 )) && RAINSENSORQTY_PULSE=rising  # pull-down circuit (rest status is 0)
(( RAIN_GPIO_STATE == 0 )) && RAINSENSORQTY_PULSE=falling # pull-up circuit   (rest status is 1)


config_check()
{
	var2check="RAINSENSOR_DEBOUNCE RAINSENSORQTY_verbose RAINSENSORQTY_LASTRAIN RAINSENSORQTY_HISTORY RAINSENSORQTY_MONITORLOG RAINSENSORQTY_MONPID RAINSENSORQTY_DIR monitor_sh"
	for var in $var2check
	do
		if [[ -z $var ]] ; then
			echo "ERROR: $var not set"
			exit 1 
		fi
	done
	if [[ -z $RAINSENSORQTY_PULSE ]] ; then
		echo "ERROR: RAIN_GPIO_STATE not set in piGarden.conf"
		exit 1
	fi
	return 0
	case $GPIO_RESISTOR in
		pull-up|pull-down|none) return 0 ;;
		*) echo "ERROR: GPIO_RESISTOR not set correctly - values are \"pull-up|pull-down|none\" "
			exit 1
			;;
	esac
}

