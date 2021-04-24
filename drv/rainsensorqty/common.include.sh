#
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "common.include.sh"
# common functions used by driver
# Version: 0.2.5
# Data: 08/Jan/2020


#note:
#RAINSENSORQTY_MONPID="$TMPDIR/rainsensorqty_monitor.pid"
#

sec2date()
{
        date --date="@$1"
}

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

check_incomplete_loop()
{
	[[ ! -f $RAINSENSORQTY_HISTORYRAW ]] && return 1
	[[ ! -f $RAINSENSORQTY_HISTORY ]] && touch $RAINSENSORQTY_HISTORY
	> $RAINSENSORQTY_HISTORYTMP

	if lastrainevent=$( rainevents 1 ) ; then
       		: # done ok
	else
        	echo "WARNING: rainevents function had errors"
		return 1
	fi

        set -- ${lastrainevent//:/ }
	local started=$1
	local before=$2
	local counter=$3

	wrongevent=$(awk -F ":" '$1=="'$started'" && $2!="'$before'" {print $0}' $RAINSENSORQTY_HISTORY) 
	if [[ -n $wrongevent ]] ; then
		echo "ERROR: wrong last rain event found: $wrongevent , right one should be: $lastrainevent"
		return 2
	fi

	if grep -q ^${lastrainevent}$ $RAINSENSORQTY_HISTORY ; then
		: # already present
		return 0
	else

		: # missing and fixed 
		if [[ $1 == tmp ]] ; then
			echo $lastrainevent > $RAINSENSORQTY_HISTORYTMP
		else
			echo $lastrainevent >> $RAINSENSORQTY_HISTORY
		fi
		return 1
	fi
}

#next function is not used anymore
rain_history()
{
	[[ ! -f $RAINSENSORQTY_HISTORYRAW ]] && return 1
	[[ ! -f $RAINSENSORQTY_HISTORY ]] && touch $RAINSENSORQTY_HISTORY
	> $RAINSENSORQTY_HISTORYTMP

	if lastrainevent=$( rainevents 1 ) ; then
       		: # done ok
	else
        	echo "WARNING: rainevents function had errors"
		return 1
	fi

#old	#if grep -q ^$(<$RAINSENSORQTY_LASTRAIN)$ $RAINSENSORQTY_HISTORY ; then
	if grep -q ^${lastrainevent}$ $RAINSENSORQTY_HISTORY ; then
		: # already present
		return 0
	else
		: # missing and fixed 
		if [[ $1 == tmp ]] ; then
			echo $lastrainevent > $RAINSENSORQTY_HISTORYTMP
		else
			echo $lastrainevent >> $RAINSENSORQTY_HISTORY
		fi
		return 0
	fi
}

rain_when_amount()
{
# from standard input
# format  $time:$endtime:$endsequence
cat - | while read line
do
        set -- ${line//:/ }
        start=$1
        stop=$2
        howmuch=$3
        printf "RAINED for %7.2f mm between %s and %s\n" $( $JQ -n "$howmuch * $RAINSENSORQTY_MMEACH" ) "$(date --date="@$start")" "$(date --date="@$stop")"
done
}

check_TMPDIR()
{
        if [[ $(df  | awk '$NF=="/tmp" {print $1}') != "tmpfs" ]] ; then
                echo "WARNING: /tmp isn't a tmp file system"
                echo -e "\tplease add to your /etc/fstab file:\n\ttmpfs           /tmp            tmpfs defaults,noatime,nosuid   0       0"
        fi
}

rainevents()
{
	if [[ ! -f $RAINSENSORQTY_HISTORYRAW ]] ; then
		#echo "WARNING: no \$RAINSENSORQTY_HISTORYRAW file"# cannot echo, redirected output
		return 1
	fi
	case $1 in
       		[0-9]|[0-9][0-9]) howmanyevent=$1 ;;
#		-1) skiplast=true ;;
		*) howmanyevent=-1 ;;
	esac

	newloop=yes
	tac $RAINSENSORQTY_HISTORYRAW | while read line
	do
		set -- ${line//:/ }
		time=$1
		sequence=$2
		if [[ $newloop == yes ]] ; then
			endtime=$time
			endsequence=$sequence
			newloop=no
		fi
		if (( sequence == 1 )) ; then
#			[[ $skiplast=true ]] && { skiplast=false ; continue ; }
			echo $time:$endtime:$endsequence
			newloop=yes
			(( event +=1 ))
		fi
		(( howmanyevent == event )) && break
	done | sort -k1n
}

removelastrain()
{
	if [[ ! -f $RAINSENSORQTY_HISTORYRAW ]] ; then
		echo "WARNING: no \$RAINSENSORQTY_HISTORYRAW file"
		return 1
	fi

	next=false
	tac $RAINSENSORQTY_HISTORYRAW | while read line
	do
		set -- ${line//:/ }
		time=$1
		sequence=$2
		[[ $next = true ]] && echo $line
		(( sequence == 1 )) && next=true
	done | tac > ${RAINSENSORQTY_HISTORYRAW}_$$
	mv ${RAINSENSORQTY_HISTORYRAW}_$$ $RAINSENSORQTY_HISTORYRAW
}
