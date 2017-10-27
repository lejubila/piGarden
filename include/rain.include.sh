#
# Controlla se se piove tramite http://api.wunderground.com/
#
function check_rain_online {

	trigger_event "check_rain_online_before" ""

	# http://www.wunderground.com/weather/api/d/docs?d=resources/phrase-glossary&MR=1
	$CURL http://api.wunderground.com/api/$WUNDERGROUND_KEY/conditions/q/$WUNDERGROUND_LOCATION.json > $TMP_PATH/check_rain_online.json
	local weather=`cat $TMP_PATH/check_rain_online.json | $JQ -M ".current_observation.weather"`
	local current_observation=`cat $TMP_PATH/check_rain_online.json | $JQ -M ".current_observation"`
	local local_epoch=`cat $TMP_PATH/check_rain_online.json | $JQ -M -r ".current_observation.local_epoch"`
	local current_state_rain_online=""
	local last_state_rain_online=`cat "$STATUS_DIR/last_state_rain_online" 2> /dev/null`
	#echo $weather
	#weather="[Light/Heavy] Drizzle"
	if [ "$weather" = "null" ]; then
		log_write "check_rain_online - failed read online data"
	else
		log_write "check_rain_online - weather=$weather, local_epoch=$local_epoch"
		#if [[ "$weather" == *"Clear"* ]]; then
		#if [[ "$weather" == *"Rain"* ]]; then
		if 	[[ "$weather" == *"Rain"* ]] || 
		 	[[ "$weather" == *"Snow"* ]] || 
		 	[[ "$weather" == *"Hail"* ]] || 
		 	[[ "$weather" == *"Ice"* ]] || 
		 	[[ "$weather" == *"Thunderstorm"* ]] || 
			[[ "$weather" == *"Drizzle"* ]]; 
		then
			current_state_rain_online='rain'
			echo $local_epoch > "$STATUS_DIR/last_rain_online"
		else
			current_state_rain_online='norain'
		fi
		echo "$current_observation" > "$STATUS_DIR/last_weather_online"
		if [ "$current_state_rain_online" != "$last_state_rain_online" ]; then
			echo "$current_state_rain_online" > "$STATUS_DIR/last_state_rain_online"
			trigger_event "check_rain_online_change" "$current_state_rain_online"
		fi
	fi

	trigger_event "check_rain_online_after" "$current_state_rain_online"
}

#
# Controlla se se piove tramite sensore
#
function check_rain_sensor {

	if [ -n "$RAIN_GPIO" ]; then 
		trigger_event "check_rain_sensor_before" ""
		local current_state_rain_sensor=""
		local last_state_rain_sensor=`cat "$STATUS_DIR/last_state_rain_sensor" 2> /dev/null`
		local s=`drv_rain_sensor_get $RAIN_GPIO`
		if [ "$s" = "$RAIN_GPIO_STATE" ]; then
			current_state_rain_sensor='rain'
			local local_epoch=`date +%s`
			echo $local_epoch > "$STATUS_DIR/last_rain_sensor"
			log_write "check_rain_sensor - now it's raining ($local_epoch)"
			#return $local_epoch	
		else
			current_state_rain_sensor='norain'
			log_write "check_rain_sensor - now is not raining"
		fi
		if [ "$current_state_rain_sensor" != "$last_state_rain_sensor" ]; then
			echo "$current_state_rain_sensor" > "$STATUS_DIR/last_state_rain_sensor"
			trigger_event "check_rain_sensor_change" "$current_state_rain_sensor"
		fi
		trigger_event "check_rain_sensor_after" "$current_state_rain_sensor"
	else
		log_write "Rain sensor not present"
	fi

}

#
# Chiude tutte le elettrovalvole se sta piovendo
# Eseguie il controllo in tempo reale sul sensore hardware e sui dati dell'ultima chiamata eseguita online
#
function close_all_for_rain {

	local close_all=0
	local now=`date +%s`

	if [[ "$NOT_IRRIGATE_IF_RAIN_ONLINE" -gt 0 && -f $STATUS_DIR/last_rain_online ]]; then
		local last_rain=`cat $STATUS_DIR/last_rain_online`
		local dif=0
		let "dif = now - last_rain"
		if [ $dif -lt $NOT_IRRIGATE_IF_RAIN_ONLINE ]; then
			close_all=1
		fi
	fi

	if [[ "$NOT_IRRIGATE_IF_RAIN_SENSOR" -gt 0 && -f $STATUS_DIR/last_rain_sensor ]]; then
		local last_rain=`cat $STATUS_DIR/last_rain_sensor`
		local dif=0
		let "dif = now - last_rain"
		if [ $dif -lt $NOT_IRRIGATE_IF_RAIN_SENSOR ]; then
			close_all=1
		fi
	fi

	if [ "$close_all" = "1" ]; then
		for i in $(seq $EV_TOTAL)
		do
			local a=EV"$i"_ALIAS
			local al=${!a}
			local a=EV"$i"_NORAIN
			local evnorain=${!a}
			ev_status $al
			local state=$?
			#echo "$al = $state"
			if [ "$state" = "1" ] && [ "$evnorain" != "1" ]; then
				ev_close $al
				log_write "close_all_for_rain - Close solenoid '$al' for rain"
			fi
		done
	fi

}


