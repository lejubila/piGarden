#
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "common.include.sh"
# common functions used by driver
# Version: 0.2.0a
# Data: 13/Aug/2019


#note:
#RAINSENSORQTY_MONPID="$TMP_PATH/rainsensorqty_monitor.pid"
#

d() # short date & time
{
date '+%X-%x'
}


drv_rainsensorqty_writelog()
{
	#2 variables - $1 function, $2 message
	if [[ $2 =~ ERROR || $2 =~ WARNING || $2 =~ RAIN || $RAINSENSORQTY_verbose = yes ]] ; then
	        echo -e "$1 - `d`\t\t$2" >> "$LOG_OUTPUT_DRV_FILE"
#        	if [[ $($WC -c <"$LOG_OUTPUT_DRV_FILE") > $LOG_FILE_MAX_SIZE )) ; then
#                	$GZIP "$LOG_OUTPUT_DRV_FILE"
#                	$MV "${LOG_OUTPUT_DRV_FILE}.gz" "${LOG_OUTPUT_DRV_FILE}.$(date +%Y%m%d%H%M).gz"
#        	fi
	fi
}


drv_rainsensorqty_check()
{
	local f="drv_rainsensorqty_check"

	if [[ -f "$RAINSENSORQTY_MONPID" ]] ; then
		local pid=$( < "$RAINSENSORQTY_MONPID" )
		drv_rainsensorqty_writelog $f "NORMAL: checking if $pid pid is running"
        	if ps -fp $pid >/dev/null ; then
			drv_rainsensorqty_writelog $f "NORMAL: $pid pid is running"
			return 0
        	else
			drv_rainsensorqty_writelog $f "ERROR: $pid pid monitor process NOT running - $RAINSENSORQTY_MONPID file contains $pid"
			return 1
        	fi
	else
		drv_rainsensorqty_writelog $f "ERROR: no raining monitor process file \$RAINSENSORQTY_MONPID"
        	return 1
	fi
}

en_echo() # enhanched echo - check verbose variable
{
	[[ $RAINSENSORQTY_verbose = yes ]] && echo "$(d) $*"
}

rain_history()
{
	[[ ! -f $RAINSENSORQTY_HISTORY ]] && touch $RAINSENSORQTY_HISTORY
	[[ ! -f $RAINSENSORQTY_LASTRAIN ]] && return 1
	if grep -q ^$(<$RAINSENSORQTY_LASTRAIN)$ $RAINSENSORQTY_HISTORY ; then
		: # do nothing
		return 2
	else
		cat $RAINSENSORQTY_LASTRAIN >> $RAINSENSORQTY_HISTORY
		return 0
	fi
}

rain_when_amount()
{
# from standard input
cat - | while read line
do
        set -- ${line//:/ }
        when=$1
        howmuch=$2
        printf "RAINED on %s for %.2f mm\n" "$(date --date="@$1")" $( $JQ -n "$howmuch * $RAINSENSORQTY_MMEACH" )
done
}

