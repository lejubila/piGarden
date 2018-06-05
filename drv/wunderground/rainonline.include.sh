#
# Ritorna lo stato delle condizioni meteo interrogando il servizio online 
#
# $i 	identificativo gpio del sensore di pioggia
#
# return output:	0  - errore durante il recupero delle condizioni meteo 
#			>0 - rilevato pioggia, timestamp del rilevamento
#			<0 - rilevato nessuna pioggia, timestamp del rilevamento
function drv_wunderground_rain_online_get {

	# http://www.wunderground.com/weather/api/d/docs?d=resources/phrase-glossary&MR=1
	$CURL http://api.wunderground.com/api/$WUNDERGROUND_KEY/conditions/q/$WUNDERGROUND_LOCATION.json > $TMP_PATH/check_rain_online.json
	local weather=`cat $TMP_PATH/check_rain_online.json | $JQ -M ".current_observation.weather"`
	local current_observation=`cat $TMP_PATH/check_rain_online.json | $JQ -M ".current_observation"`
	local local_epoch=`cat $TMP_PATH/check_rain_online.json | $JQ -M -r ".current_observation.local_epoch"`

	if [ "$weather" = "null" ]; then
		echo "0"
	else
		if 	[[ "$weather" == *"Rain"* ]] || 
		 	[[ "$weather" == *"Snow"* ]] || 
	 		[[ "$weather" == *"Hail"* ]] || 
			[[ "$weather" == *"Ice"* ]] || 
			[[ "$weather" == *"Thunderstorm"* ]] || 
			[[ "$weather" == *"Drizzle"* ]]; 
		then
			echo $local_epoch
		else
			echo "-$local_epoch"
		fi
		echo "$current_observation" > "$STATUS_DIR/last_weather_online"
	fi

}


