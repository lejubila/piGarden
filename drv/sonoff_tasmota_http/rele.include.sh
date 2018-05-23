#
# Inizializzazione rele 
#
# $1 identificativo relè da inizializzare
#
function drv_sonoff_tasmota_http_rele_init {
	drv_remote_rele_open "$1"
}

#
# Apertura rele 
#
# $1 identificativo relè da aprire (chiude l'elettrovalvola)
#
function drv_sonoff_tasmota_http_rele_open {

	local remote=`echo $1 | $CUT -d':' -f3,3`
	local remote_alias=`echo $1 | $CUT -d':' -f4,4`

	local command="cmnd=$remote_alias%20Off"

	echo "remote=$remote"
	echo "remote_alias=$remote_alias"
	echo "command=$command"

	local response=$(drv_sonoff_tasmota_http_command "$remote" "$command")

	echo "response=$response"
	local jskey=${remote_alias^^}

	local result=$(echo $response|$JQ -M ".$jskey")
	echo "result=$result"
	if [[ "$result" != "\"OFF\"" ]]; then
		local error="Command error: $response"
		error="${error%\"}"
		error="${error#\"}"
		echo "error=$error"
	        log_write "Remote rele open error: $error"
        	message_write "warning" "Remote rele open error: $error"
		return 1
	fi
}

#
# Chiusura rele 
#
# $1 identificativo relè da chiudere (apre l'elettrovalvola)
#
function drv_sonoff_tasmota_http_rele_close {

	local remote=`echo $1 | $CUT -d':' -f3,3`
	local remote_alias=`echo $1 | $CUT -d':' -f4,4`

	local command="cmnd=$remote_alias%20On"

	echo "remote=$remote"
	echo "remote_alias=$remote_alias"
	echo "command=$command"

	local response=$(drv_sonoff_tasmota_http_command "$remote" "$command")

	echo "response=$response"
	local jskey=${remote_alias^^}

	local result=$(echo $response|$JQ -M ".$jskey")
	echo "result=$result"
	if [[ "$result" != "\"ON\"" ]]; then
		local error="Command error: $response"
		error="${error%\"}"
		error="${error#\"}"
		echo "error=$error"
	        log_write "Remote rele close error: $error"
        	message_write "warning" "Remote rele close error: $error"
		return 1
	fi

}

