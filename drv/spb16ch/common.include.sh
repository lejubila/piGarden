#
# Funzioni comuni per il driver spb16ch
#

#
# Abilita una scheda spb16ch in modo che possa esseregli impartito un comando successivamente
# $1 identificativo scheda da abilitare
#
function drv_spb16ch_board_enable {

	local board_id=$1

        local a=SPB16CH"$board_id"_GPIO
        local gpio_n=${!a}

        echo "** drv_spb16ch_board_enable() - Enable board: $board_id - gpio $gpio_n"
        $GPIO -g write $gpio_n $SPB16CH_GPIO_ON

}

#
# Disabilita una scheda spb16ch 
# $1 identificativo scheda da disabilitare
#
function drv_spb16ch_board_disable {

	local board_id=$1

        local a=SPB16CH"$board_id"_GPIO
        local gpio_n=${!a}

        echo "** drv_spb16ch_board_disable() - Disable board: $board_id - gpio $gpio_n"
        $GPIO -g write $gpio_n $SPB16CH_GPIO_OFF

}

#
# Disabilita tutte le schede 
#
function drv_spb16ch_board_disable_all {

        echo "** drv_spb16ch_board_disable_all() - Boads id: ${SPB16CH_USED_ID[@]}"

        local board_id
        for board_id in ${SPB16CH_USED_ID[@]}
        do
                local a=SPB16CH"$board_id"_GPIO
                local gpio_n=${!a}

                echo "** drv_spb16ch_board_disable_all() - Disable board: $board_id - gpio $gpio_n"
                $GPIO -g write $gpio_n $SPB16CH_GPIO_OFF
        done

}

#
# Memorizza in un file di appoggio gli id delle schede spb16ch utilizzate
#
function drv_spb16ch_boards_id_store {

	echo "${SPB16CH_USED_ID[@]}" > "$SPB16CH_BOARD_ID_STORE_FILE"

}

#
# Recupera gli di delle schede spb16ch utilizzate leggendoli dal file di appoggio
# $1 identificativi schede da salvare
#
function drv_spb16ch_boards_id_load {

	if [ -f "$SPB16CH_BOARD_ID_STORE_FILE" ]; then
		for board_id in $(cat "$SPB16CH_BOARD_ID_STORE_FILE")
		do
			SPB16CH_USED_ID+=("$board_id")
		done
	else
		log_write "spb16ch: file $SPB16CH_BOARD_ID_STORE_FILE not found: remember to run 'piGarden init' to generate the file"
	fi

}
