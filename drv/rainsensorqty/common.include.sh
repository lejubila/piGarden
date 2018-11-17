#
# Funzioni comuni utilizzate dal driver
#
#RAINSENSORQTY_MONPID="$TMP_PATH/rainsensorqty_monitor.pid"
#

function drv_rainsensorqty_check () {

	if [[ -f "$RAINSENSORQTY_MONPID" && -z "$RAINSENSORQTY_MONPID" ]] ; then
		pid=$( < "$RAINSENSORQTY_MONPID" )
		echo "drv_rainsensorqty_check - NORMAL: checking if $pid pid is running" >> "$LOG_OUTPUT_DRV_FILE"
		log_write "$$ pid monitor process - see $RAINSENSORQTY_MONPID"
        	if ps -fp $pid >/dev/null ; then
			echo "drv_rainsensorqty_check - NORMAL: $pid pid is running" >> "$LOG_OUTPUT_DRV_FILE"
			return 0
        	else
			echo "drv_rainsensorqty_check - NORMAL: $pid pid is NOT running" >> "$LOG_OUTPUT_DRV_FILE"
			return 1
        	fi
	else
		echo "drv_rainsensorqty_check - ERROR: no raining monitor process file \$RAINSENSORQTY_MONPID" >> "$LOG_OUTPUT_DRV_FILE"
        	return 1
	fi
}
