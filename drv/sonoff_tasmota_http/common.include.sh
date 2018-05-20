#
# Funzioni comuni utilizzate dal driver
#

#
# Invia un comando al modulo sonoff tramite http
#
# $1	identificativo modulo sonoff
# $2	comando da eseguire
#
function drv_sonoff_tasmota_http_command {

	local remote="$1"
	local command="$2"

	local remote_ip_var=$remote"_IP"
	local remote_user_var=$remote"_USER"
	local remote_pwd_var=$remote"_PWD"

	local remote_ip="${!remote_ip_var}"
	local remote_user="${!remote_user_var}"
	local remote_pwd="${!remote_pwd_var}"

	local url="http://$remore_ip/cm"
	local credentials=""
	local response=""

	#$CURL -LI http://$remote_ip/ -o /dev/null -w '%{http_code}\n' -s

	if [[ ! -z $remote_user ]] && [[ ! -z $remote_pwd ]]; then
		credentials="user=$remote_user&password=$remote_pwd&"
	fi

	url="$url?$credentials$command"

	$CURL -sb -H "$url"

	#$CURL -LI $url -o /dev/null -w '%{http_code}\n' -s

}


