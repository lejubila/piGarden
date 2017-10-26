#
# Triggered an event and executge associated scripts
# $1 event
# $2 cause
#

function trigger_event {

	## check_rain_online_after
	## check_rain_online_before
	## check_rain_online_change
	## check_rain_sensor_after
	## check_rain_sensor_before
	## check_rain_sensor_change
	## ev_close_after
	## ev_close_before
	## ev_open_after
	## ev_open_before
	## init_after
	## init_before

	local EVENT="$1"
	local CAUSE="$2"
	local current_event_dir="$EVENT_DIR/$EVENT"

	if [ -d "$current_event_dir" ]; then
		local FILES="$current_event_dir/*"
		for f in $FILES
		do
			if [ -x "$f" ]; then
				$f "$EVENT" "$CAUSE" `date +%s`  &> /dev/null &
				local ec=$?
				if [ $ec -ne 0 ]; then
					log_write "Stop events chain for exit code $ec in $current_event_dir/$f"
					exit
				fi
			fi
		done

	fi

}


