#
# Questa funzione viene inviocata dalla funzione "setup_drv" ad ogni avvio di piGarden
# esegue il setup del driver recuperando gli identificativi delle schede sbp16ch usati
#
function drv_spb16ch_setup {

        # Cerca gli identificativi delle schede spb16ch utilizzate per i rele utilizzati per le zone
        for i in $(seq $EV_TOTAL)
        do
                local a=EV"$i"_GPIO
                local gpio="${!a}"
                if [[ "$gpio" == drv:spb16ch:* ]]; then
		        local rele_id=`echo $gpio | $CUT -d':' -f3,3`
		        local rele_data=${SPB16CH_RELE_MAP[$rele_id]}
		        if [[ ! -z $rele_data ]]; then
				local board_id=${rele_data:9:1}
				if [[ ! " ${SPB16CH_USED_ID[@]} " =~ " ${board_id} " ]]; then
					SPB16CH_USED_ID+=("$board_id")
				fi
		        fi
                fi
        done

        # Cerca gli identificativi schede spb16ch utilizzate che gestiscono l'alimentazione delle elettrovalvole bistabili
        for gpio in "$SUPPLY_GPIO_1" "$SUPPLY_GPIO_2"
        do
                if [[ "$gpio" == drv:spb16ch:* ]]; then
		        local rele_id=`echo $gpio | $CUT -d':' -f3,3`
		        local rele_data=${SPB16CH_RELE_MAP[$rele_id]}
		        if [[ ! -z $rele_data ]]; then
				local board_id=${rele_data:9:1}
				if [[ ! " ${SPB16CH_USED_ID[@]} " =~ " ${board_id} " ]]; then
					SPB16CH_USED_ID+=("$board_id")
				fi
		        fi
                fi
        done

	echo "Identificativi board spb16ch utilizzate: ${SPB16CH_USED_ID[@]}"

}

