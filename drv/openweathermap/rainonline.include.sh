#
# Ritorna lo stato delle condizioni meteo interrogando il servizio online 
#
# $i 	identificativo gpio del sensore di pioggia
#
# return output:	0  - errore durante il recupero delle condizioni meteo 
#			>0 - rilevato pioggia, timestamp del rilevamento
#			<0 - rilevato nessuna pioggia, timestamp del rilevamento
function drv_openweathermap_rain_online_get {

	# http://www.wunderground.com/weather/api/d/docs?d=resources/phrase-glossary&MR=1
	$CURL "http://api.openweathermap.org/data/2.5/weather?$OPENWEATHERMAP_LOCATION&units=metric&appid=$OPENWEATHERMAP_KEY" > $TMP_PATH/check_rain_online.openweathermap.json
	local weather=`cat $TMP_PATH/check_rain_online.openweathermap.json | $JQ -M ".weather[0].main"`

	local wind_deg=$(cat $TMP_PATH/check_rain_online.openweathermap.json | $JQ -r -M ".wind.deg")
	local wind_speed=$(cat $TMP_PATH/check_rain_online.openweathermap.json | $JQ -r -M ".wind.speed")
	if [ "$wind_speed" == "null" ]; then
		#wind_speed=$($JQ -n $wind_speed*3600/1000)
		wind_speed=0
	fi


	local weather="$(cat $TMP_PATH/check_rain_online.openweathermap.json | $JQ -r -M ".weather[0].description")"
	local ico=$(cat $TMP_PATH/check_rain_online.openweathermap.json | $JQ -r -M ".weather[0].icon")
	weather=$(drv_openweathermap_get_wather "$weather")
	ico=$(drv_openweathermap_get_ico "$ico")

	local current_observation=$(cat <<EOF
{
  "display_location": {
    "city": "$(cat $TMP_PATH/check_rain_online.openweathermap.json | $JQ -r -M ".name")"
  },
  "observation_epoch": "$(cat $TMP_PATH/check_rain_online.openweathermap.json | $JQ -r -M ".dt")",
  "local_epoch": "$(cat $TMP_PATH/check_rain_online.openweathermap.json | $JQ -r -M ".dt")",
  "local_tz_long": "$OPENWEATHERMAP_TZ",
  "weather": "$weather",
  "temp_c": $(cat $TMP_PATH/check_rain_online.openweathermap.json | $JQ -r -M ".main.temp"),
  "relative_humidity": "$(cat $TMP_PATH/check_rain_online.openweathermap.json | $JQ -r -M ".main.humidity")%",
  "wind_dir": "$(deg2dir $wind_deg)",
  "wind_degrees": $wind_deg,
  "wind_kph": $wind_speed,
  "wind_gust_kph": "--",
  "pressure_mb": "$(cat $TMP_PATH/check_rain_online.openweathermap.json | $JQ -r -M ".main.pressure")",
  "dewpoint_c": "--",
  "feelslike_c": "--",
  "icon_url": "$ico"
}
EOF
)
#  "icon_url": "http://openweathermap.org/img/w/$(cat $TMP_PATH/check_rain_online.openweathermap.json | $JQ -r -M ".weather[0].icon").png"

	#local current_observation=`cat $TMP_PATH/check_rain_online.json | $JQ -M ".current_observation"`

	if [ "$weather" = "null" ]; then
		echo "0"
	else
		echo "$current_observation" > "$STATUS_DIR/last_weather_online"
		local local_epoch=`cat $STATUS_DIR/last_weather_online | $JQ -M -r ".local_epoch"`
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
	fi

}


