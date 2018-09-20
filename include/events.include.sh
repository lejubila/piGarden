#
# Triggered an event and executge associated scripts
# $1 event
#

function trigger_event {

	local EVENT="$1"
	local CAUSE="$2"
	local current_event_dir="$EVENT_DIR/$EVENT"

	if [ -d "$current_event_dir" ]; then
		local FILES="$current_event_dir/*"
		for f in $FILES
		do
			if [ -x "$f" ]; then
				case "$EVENT" in
					"ev_open_before" | "ev_open_after")
						ALIAS="$2"
						FORCE="$3"
						$f "$EVENT" "$ALIAS" "$FORCE" `date +%s`  &> /dev/null 
						;;

					"ev_open_in_before")
						ALIAS="$2"
						FORCE="$3"
						local MINUTE_START="$4"
						local MINUTE_STOP="$5"
						$f "$EVENT" "$ALIAS" "$FORCE" "$MINUTE_START" "$MINUTE_STOP" `date +%s`  &> /dev/null 
						;;

					"ev_open_in_after")
						ALIAS="$2"
						FORCE="$3"
						local CRON_START="$4"
						local CRON_STOP="$5"
						$f "$EVENT" "$ALIAS" "$FORCE" "$CRON_START" "$CRON_STOP" `date +%s`  &> /dev/null 
						;;

					"ev_close_before" | "ev_close_after")
						ALIAS="$2"
						$f "$EVENT" "$ALIAS" `date +%s`  &> /dev/null 
						;;


					"check_rain_sensor_before" | "check_rain_sensor_after" | "check_rain_sensor_change")
						STATE="$2"
						$f "$EVENT" "$STATE" `date +%s`  &> /dev/null 
						;;

					"check_rain_online_before")
						STATE="$2"
						$f "$EVENT" "$STATE" `date +%s`  &> /dev/null 
						;;

					"check_rain_online_after" | "check_rain_online_change")
						STATE="$2"
						WEATHER="$3"
						$f "$EVENT" "$STATE" "$WEATHER" `date +%s`  &> /dev/null 
						;;


					"init_before" | "init_after")
						STATE="$2"
						$f "$EVENT" `date +%s`  &> /dev/null 
						;;

					"cron_add_before" | "cron_add_after")
						local CRON_TYPE="$2"
						local CRON_ARG="$3"
						local CRON_ELEMENT="$4"
						$f "$EVENT" "$CRON_TYPE" "$CRON_ARG" "$CRON_ELEMENT" `date +%s`  &> /dev/null 
						;;

					"cron_del_before" | "cron_del_after")
						local CRON_TYPE="$2"
						local CRON_ARG="$3"
						$f "$EVENT" "$CRON_TYPE" "$CRON_ARG" `date +%s`  &> /dev/null 
						;;

					"exec_poweroff_before" | "exec_poweroff_after" | "exec_reboot_before" | "exec_reboot_after" )
						$f "$EVENT" `date +%s`  &> /dev/null 
						;;

					*)
						$f "$EVENT" "$CAUSE" `date +%s`  &> /dev/null 
						;;
				esac

				local ec=$?
				#echo "$EVENT ec=$ec" >> /tmp/piGarden.testevent

				mqtt_status &

				if [ $ec -ne 0 ]; then
					log_write "Stop events chain for exit code $ec in $current_event_dir/$f"
					return $ec
				fi
			fi
		done

	fi

}


