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
			local address_num=${rele_data:0:2}
		        if [[ ! -z $rele_data ]]; then
				if [[ ! " ${address_used[@]} " =~ " ${address_num} " ]]; then
					address_used+=("$address_num")
				fi
		        fi
                fi
        done

        # Cerca gli indirizzi delle schede spb16ch utilizzate per i rele utilizzate per la gestione alimentazione 
        for gpio in "$SUPPLY_GPIO_1" "$SUPPLY_GPIO_2"
        do
                if [[ "$gpio" == drv:spb16ch:* ]]; then
		        local rele_id=`echo $gpio | $CUT -d':' -f3,3`
		        local rele_data=${SPB16CH_RELE_MAP[$rele_id]}
			local address_num=${rele_data:0:2}
		        if [[ ! -z $rele_data ]]; then
				if [[ ! " ${address_used[@]} " =~ " ${address_num} " ]]; then
					address_used+=("$address_num")
				fi
		        fi
                fi
        done

	# Esegue l'inizializzazione delle schede spb16ch trovate
	for address_num in ${address_used[@]}
	do
		echo "****** address_num = $address_num *******"
		$DIR_SCRIPT/drv/spb16ch/scripts/mux_channel.py $address_num 0
		$DIR_SCRIPT/drv/spb16ch/scripts/gpo_init.py 25 255 0
		$DIR_SCRIPT/drv/spb16ch/scripts/mux_channel.py $address_num 1
		$DIR_SCRIPT/drv/spb16ch/scripts/gpo_init.py 25 255 0
		$DIR_SCRIPT/drv/spb16ch/scripts/mux_channel.py $address_num 0
	done

}

