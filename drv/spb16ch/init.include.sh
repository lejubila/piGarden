#
# Questa funzione viene inviocata dalla funzione "init" di piGarden se sono presenti elettrovalvole o sensori che utilizzano questo driver
#
function drv_spb16ch_init {

        declare -a address_used
        address_used=()
	SPB16CH_USED_ID=()

	local address=""
	local board_id=""

        # Cerca gli indirizzi delle schede spb16ch utilizzate per i rele utilizzati per le zone
        for i in $(seq $EV_TOTAL)
        do
                local a=EV"$i"_GPIO
                local gpio="${!a}"
                if [[ "$gpio" == drv:spb16ch:* ]]; then
		        local rele_id=`echo $gpio | $CUT -d':' -f3,3`
		        local rele_data=${SPB16CH_RELE_MAP[$rele_id]}
		        if [[ ! -z $rele_data ]]; then
				local address_num=${rele_data:0:2}
				local board_id=${rele_data:9:1}
				if [[ ! " ${address_used[@]} " =~ " ${address_num} " ]]; then
					address_used+=("$address_num")
					SPB16CH_USED_ID+=("$board_id")
				fi
		        fi
                fi
        done

        # Cerca gli indirizzi delle schede spb16ch utilizzate per i rele che gestiscono l'alimentazione delle elettrovalvole bistabili
        for gpio in "$SUPPLY_GPIO_1" "$SUPPLY_GPIO_2"
        do
                if [[ "$gpio" == drv:spb16ch:* ]]; then
		        local rele_id=`echo $gpio | $CUT -d':' -f3,3`
		        local rele_data=${SPB16CH_RELE_MAP[$rele_id]}
		        if [[ ! -z $rele_data ]]; then
				local address_num=${rele_data:0:2}
				local board_id=${rele_data:9:1}
				if [[ ! " ${address_used[@]} " =~ " ${address_num} " ]]; then
					address_used+=("$address_num")
					SPB16CH_USED_ID+=("$board_id")
				fi
		        fi
                fi
        done

	# Memorizza gli id delle schede usate 
	drv_spb16ch_boards_id_store

	# Esegue l'inizializzazione dei gpio che gestiscono l'abilitazine/disabilitazione delle schede
	local board_id
	for board_id in ${SPB16CH_USED_ID[@]}
	do
                local a=SPB16CH"$board_id"_GPIO
                local gpio_n=${!a}

		echo "******** Number used board: $board_id - inizializzazione gpio $gpio_n"
		$GPIO -g mode $gpio_n out
	done
	drv_spb16ch_board_disable_all	

	# Esegue l'inizializzazione delle schede spb16ch trovate
	local address_num=""
	local board_num=""
	for i in ${!address_used[@]}
	do
		address_num=${address_used[$i]}
		board_num=${SPB16CH_USED_ID[$i]}
		drv_spb16ch_board_enable $board_num
		echo "****** Inizializzazione address_num = $address_num - board_num = $board_num *******"
		$DIR_SCRIPT/drv/spb16ch/scripts/mux_channel.py $address_num 0
		$DIR_SCRIPT/drv/spb16ch/scripts/gpo_init.py 25 255 0
		$DIR_SCRIPT/drv/spb16ch/scripts/mux_channel.py $address_num 1
		$DIR_SCRIPT/drv/spb16ch/scripts/gpo_init.py 25 255 0
		$DIR_SCRIPT/drv/spb16ch/scripts/mux_channel.py $address_num 0
		drv_spb16ch_board_disable $board_id
	done

}

