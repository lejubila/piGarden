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
	local address_num=${rele_data:0:2}
	local channel_num=${rele_data:3:1}
	local rele_num=${rele_data:5:3}
	local board_id=${rele_data:9:1}

	drv_spb16ch_board_enable $board_id

	echo address_num=$address_num
	echo channel_num=$channel_num
	echo rele_num=$rele_num
	$DIR_SCRIPT/drv/spb16ch/scripts/mux_channel.py $address_num $channel_num
	$DIR_SCRIPT/drv/spb16ch/scripts/gpo_init.py $address_num $rele_num 0

	drv_spb16ch_board_disable $board_id

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
	local address_num=${rele_data:0:2}
	local channel_num=${rele_data:3:1}
	local rele_num=${rele_data:5:3}
	local board_id=${rele_data:9:1}

	drv_spb16ch_board_enable $board_id

	echo address_num=$address_num
	echo channel_num=$channel_num
	echo rele_num=$rele_num
	$DIR_SCRIPT/drv/spb16ch/scripts/mux_channel.py $address_num $channel_num
	$DIR_SCRIPT/drv/spb16ch/scripts/gpo_init.py $address_num $rele_num 1

	drv_spb16ch_board_disable $board_id

}

