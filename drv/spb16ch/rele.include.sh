#
# Inizializzazione rele 
#
# $1 identificativo relè da inizializzare
#
function drv_spb16ch_rele_init {

	drv_spb16ch_rele_open "$1"
}

#
# Apertura rele 
#
# $1 identificativo relè da aprire 
#
function drv_spb16ch_rele_open {

	local rele_id=`echo $1 | $CUT -d':' -f3,3`
	local rele_data=${SPB16CH_RELE_MAP[$rele_id]}
	if [[ -z $rele_data ]]; then
		local message="Error - Rele map not defined - rele_id=$rele_id - ($1)"
		log_write "$message"
		message_write "warning" "$message"
	fi
	local channel_num=${rele_data:0:2}
	local rele_num=${rele_data:2:3}

	echo channel_num=$channel_num
	echo rele_num=$rele_num
	$DIR_SCRIPT/drv/spb16ch/scripts/mux_channel.py 72 $channel_num
	$DIR_SCRIPT/drv/spb16ch/scripts/gpo_init.py 72 $rele_num 0

}

#
# Chiusura rele 
#
# $1 identificativo relè da chiudere
#
function drv_spb16ch_rele_close {

	local rele_id=`echo $1 | $CUT -d':' -f3,3`
	local rele_data=${SPB16CH_RELE_MAP[$rele_id]}
	if [[ -z $rele_data ]]; then
		local message="Error - Rele map not defined - rele_id=$rele_id - ($1)"
		log_write "$message"
		message_write "warning" "$message"
	fi
	local channel_num=${rele_data:0:2}
	local rele_num=${rele_data:2:3}

	echo channel_num=$channel_num
	echo rele_num=$rele_num
	$DIR_SCRIPT/drv/spb16ch/scripts/mux_channel.py 72 $channel_num
	$DIR_SCRIPT/drv/spb16ch/scripts/gpo_init.py 72 $rele_num 1

}

