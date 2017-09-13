#
# Questa funzione viene inviocata dalla funzione "init" di piGarden se sono presenti elettrovalvole o sensori che utilizzano questo driver
#
function drv_spb16ch_init {

        declare -a address_used
        address_used=()

	local address=""

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
				if [[ ! " ${address_used[@]} " =~ " ${address_num} " ]]; then
					address_used+=("$address_num")
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
				if [[ ! " ${address_used[@]} " =~ " ${address_num} " ]]; then
					address_used+=("$address_num")
				fi
		        fi
                fi
        done

	# Esegue l'inizializzazione delle schede spb16ch trovate
	local address_num
	for address_num in ${address_used[@]}
	do
		echo "****** Inizializzazione address_num = $address_num *******"
		$DIR_SCRIPT/drv/spb16ch/scripts/mux_channel.py $address_num 0
		$DIR_SCRIPT/drv/spb16ch/scripts/gpo_init.py 25 255 0
		$DIR_SCRIPT/drv/spb16ch/scripts/mux_channel.py $address_num 1
		$DIR_SCRIPT/drv/spb16ch/scripts/gpo_init.py 25 255 0
		$DIR_SCRIPT/drv/spb16ch/scripts/mux_channel.py $address_num 0
	done

	# Esegue l'inizializzazione dei gpio che gestiscono l'abilitazine/disabilitazione delle schede
	local board_id
	for board_id in ${SPB16CH_USED_ID[@]}
	do
                local a=SPB16CH"$board_id"_GPIO
                local gpio_n=${!a}

		echo "******** Number used board: $board_id - inizializzazione gpio $gpio_n"
		$GPIO -g mode $gpio_n out
	done

}

