#
# Inizializzazione rele 
#
# $1 identificativo relè da inizializzare
#
function drv_remote_rele_init {

	drv_remote_rele_open "$1"
}

#
# Apertura rele 
#
# $1 identificativo relè da aprire (chiude l'elettrovalvola)
#
function drv_remote_rele_open {

	local remote=`echo $1 | $CUT -d':' -f3,3`
	local remote_alias=`echo $1 | $CUT -d':' -f4,4`

	local command="close $remote_alias"

	echo "remote=$remote"
	echo "remote_alias=$remote_alias"
	echo "command=$command"

	local response=$(drv_remote_command "$remote" "$command")

	echo "response=$response"

	local result=$(echo $response|$JQ -M ".error.description")
	echo "result=$result"
	if [[ "$result" != "\"\"" ]]; then
		local error=$result
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
function drv_remote_rele_close {

	local remote=`echo $1 | $CUT -d':' -f3,3`
	local remote_alias=`echo $1 | $CUT -d':' -f4,4`

	local command="open $remote_alias force"

	echo "remote=$remote"
	echo "remote_alias=$remote_alias"
	echo "command=$command"

	local response=$(drv_remote_command "$remote" "$command")

	echo "response=$response"

	local result=`echo $response|$JQ -M ".error.description"`
	echo "result=$result"
	if [[ "$result" != "\"\"" ]]; then
		local error=$result
		error="${error%\"}"
		error="${error#\"}"
		echo "error=$error"
	        log_write "Remote rele open error: $error"
        	message_write "warning" "Remote rele open error: $error"
		return 1
	fi
}

