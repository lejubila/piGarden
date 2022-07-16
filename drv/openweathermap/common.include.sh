#
# Funzioni comuni utilizzate dal driver
#

#
# Recupera la descrizione della condizione meteo
#
# $1 condizione meteo recuperata dalle api
#
function drv_openweathermap_get_wather {

	declare -A w

	w["thunderstorm with light rain"]="Thunderstorms and Rain"
	w["thunderstorm with rain"]="Thunderstorms and Rain"
	w["thunderstorm with heavy rain"]="Thunderstorms and Rain"
	w["light thunderstorm"]="Thunderstorm"
	w["thunderstorm"]="Thunderstorm"
	w["heavy thunderstorm"]="Thunderstorm"
	w["ragged thunderstorm"]="Thunderstorm"
	w["thunderstorm with light drizzle"]="Thunderstorms and Rain"
	w["thunderstorm with drizzle"]="Thunderstorms and Rain"
	w["thunderstorm with heavy drizzle"]="Thunderstorms and Rain"

	w["light intensity drizzle"]="Drizzle"
	w["drizzle"]="Drizzle"
	w["heavy intensity drizzle"]="Drizzle"
	w["light intensity drizzle rain"]="Drizzle"
	w["drizzle rain"]="Drizzle"
	w["heavy intensity drizzle rain"]="Drizzle"
	w["shower rain and drizzle"]="Drizzle"
	w["heavy shower rain and drizzle"]="Drizzle"
	w["shower drizzle"]="Drizzle"

	w["light rain"]="Rain Mist"
	w["moderate rain"]="Rain"
	w["heavy intensity rain"]="Rain"
	w["very heavy rain"]="Rain"
	w["extreme rain"]="Rain"
	w["freezing rain"]="Freezing Rain"
	w["light intensity shower rain"]="Rain"
	w["shower rain"]="Rain"
	w["heavy intensity shower rain"]="Rain"
	w["ragged shower rain"]="Rain"

	w["light snow"]="Snow"
	w["snow"]="Snow"
	w["heavy snow"]=""
	w["sleet"]="Snow Grains"
	w["shower sleet"]="Snow Grains"
	w["light rain and snow"]="Snow"
	w["rain and snow"]="Snow"
	w["light shower snow"]="Snow"
	w["shower snow"]="Snow"
	w["heavy shower snow"]="Snow"

	w["mist"]="Mist"
	w["smoke"]="Smoke"
	w["haze"]="Haze"
	w["sand, dust whirls"]="Dust Whirls"
	w["fog"]="Fog"
	w["sand"]="Sand"
	w["dust"]="Widespread Dust"
	w["volcanic ash"]="Volcanic Ash"
	w["squalls"]="Squalls"
	w["tornado"]="Tornado"

	w["clear sky"]="Clear"

	w["few clouds"]="Partly Cloudy"
	w["scattered clouds"]="Scattered Clouds"
	w["broken clouds"]="Partly Cloudy"
	w["overcast clouds"]="Mostly Cloudy"

	local weather=${w[$1]}

	if [ -z "$weather" ]; then
		weather="$1"
	fi

	echo $weather

}																												    

#
# Recupera la l'icona rappresentativa delle condizione meteo
#
# $1 nome dell'icona recuperato delle api weather.icon
#
function drv_openweathermap_get_ico {

	declare -A w

	w["01d"]="http://www.wunderground.com/static/i/c/k/clear.gif"
	w["01n"]="http://www.wunderground.com/static/i/c/k/nt_clear.gif"
	w["02d"]="http://www.wunderground.com/static/i/c/k/partlycloudy.gif"
	w["02n"]="http://www.wunderground.com/static/i/c/k/nt_partlycloudy.gif"
	w["03d"]="http://www.wunderground.com/static/i/c/k/cloudy.gif"
	w["03n"]="http://www.wunderground.com/static/i/c/k/nt_cloudy.gif"
	w["04d"]="http://www.wunderground.com/static/i/c/k/cloudy.gif"
	w["04n"]="http://www.wunderground.com/static/i/c/k/nt_cloudy.gif"
	w["09d"]="http://www.wunderground.com/static/i/c/k/sleet.gif"
	w["09n"]="http://www.wunderground.com/static/i/c/k/nt_sleet.gif"
	w["10d"]="http://www.wunderground.com/static/i/c/k/rain.gif"
	w["10n"]="http://www.wunderground.com/static/i/c/k/nt_rain.gif"
	w["11d"]="http://www.wunderground.com/static/i/c/k/tstorms.gif"
	w["11n"]="http://www.wunderground.com/static/i/c/k/nt_tstorms.gif"
	w["13d"]="http://www.wunderground.com/static/i/c/k/snow.gif"
	w["13n"]="http://www.wunderground.com/static/i/c/k/nt_snow.gif"
	w["50d"]="http://www.wunderground.com/static/i/c/k/fog.gif"
	w["50n"]="http://www.wunderground.com/static/i/c/k/nt_fog.gif"

	local ico=${w[$1]}

	if [ -z "$ico" ]; then
		ico="$1"
	fi

	echo $ico

}																												    


