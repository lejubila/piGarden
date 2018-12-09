#
# Funzioni comuni utilizzate dal driver
#
#RAINSENSORQTY_MONPID="$TMP_PATH/rainsensorqty_monitor.pid"
#


function drv_rainsensorqty_writelog {
	#2 variables - $1 function, $2 message
        echo -e "$1 - `date`\t\t$2" >> "$LOG_OUTPUT_DRV_FILE"
}


function drv_rainsensorqty_check () {
	local f="drv_rainsensorqty_check"

	if [[ -f "$RAINSENSORQTY_MONPID" ]] ; then
		local pid=$( < "$RAINSENSORQTY_MONPID" )
		drv_rainsensorqty_writelog $f "NORMAL: checking if $pid pid is running"
        	if ps -fp $pid >/dev/null ; then
			drv_rainsensorqty_writelog $f "NORMAL: $pid pid is running"
			return 0
        	else
			drv_rainsensorqty_writelog $f "$pid pid monitor process NOT running - $RAINSENSORQTY_MONPID file contains $pid"
			return 1
        	fi
	else
		drv_rainsensorqty_writelog $f "ERROR: no raining monitor process file \$RAINSENSORQTY_MONPID"
        	return 1
	fi
}
