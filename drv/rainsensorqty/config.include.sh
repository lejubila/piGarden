#
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "config.include.sh"
# specific driver config file
# Version: 0.2.0
# Data: 11/Aug/2019

RAINSENSOR_ANTIBOUNCE=0.3 # 0.3 seconds for manage antibounce of reed contact

RAINSENSORQTY_verbose="no" # yes/no

RAINSENSORQTY_LASTRAIN="$STATUS_DIR/rainsensorqty_lastrain"
RAINSENSORQTY_HISTORY="$STATUS_DIR/rainsensorqty_history"

RAINSENSORQTY_MONITORLOG="$DIR_SCRIPT/log/rainsensorqty_monitor.log"

RAINSENSORQTY_MONPID="$TMP_PATH/rainsensorqty_monitor.pid"

RAINSENSORQTY_DIR="$DIR_SCRIPT/drv/rainsensorqty"

monitor_sh="$RAINSENSORQTY_DIR/drv_rainsensorqty_monitor.sh"


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

