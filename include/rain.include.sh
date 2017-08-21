#
# Controlla se se piove tramite http://api.wunderground.com/
#
function check_rain_online {
	# http://www.wunderground.com/weather/api/d/docs?d=resources/phrase-glossary&MR=1
	$CURL http://api.wunderground.com/api/$WUNDERGROUND_KEY/conditions/q/$WUNDERGROUND_LOCATION.json > $TMP_PATH/check_rain_online.json
	local weather=`cat $TMP_PATH/check_rain_online.json | $JQ -M ".current_observation.weather"`
	local current_observation=`cat $TMP_PATH/check_rain_online.json | $JQ -M ".current_observation"`
	local local_epoch=`cat $TMP_PATH/check_rain_online.json | $JQ -M -r ".current_observation.local_epoch"`
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
			#echo "ECCOMI!!!!!"
			echo $local_epoch > "$STATUS_DIR/last_rain_online"
			return $local_epoch	
		fi
		echo "$current_observation" > "$STATUS_DIR/last_weather_online"
	fi
}

#
# Controlla se se piove tramite sensore
#
function check_rain_sensor {

	if [ -n "$RAIN_GPIO" ]; then 
		#local s=`$GPIO -g read $RAIN_GPIO`
		local s=`drv_rain_sensor_get $RAIN_GPIO`
		if [ "$s" = "$RAIN_GPIO_STATE" ]; then
			local local_epoch=`date +%s`
			echo $local_epoch > "$STATUS_DIR/last_rain_sensor"
			log_write "check_rain_sensor - now it's raining ($local_epoch)"
			return $local_epoch	
		else
			log_write "check_rain_sensor - now is not raining"
		fi
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
			ev_status $al
			local state=$?
			#echo "$al = $state"
			if [ "$state" = "1" ]; then
				ev_close $al
				log_write "close_all_for_rain - Close solenoid '$al' for rain"
			fi
		done
	fi

}


