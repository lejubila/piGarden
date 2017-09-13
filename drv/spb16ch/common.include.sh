#
# Funzioni comuni per il driver spb16ch
#

#
# Abilita una scheda spb16ch in modo che possa esseregli impartito un comando successivamente
# $1 identificativo scheda da abilitare
#
function drv_spb16ch_board_enable {

	local board_id=$1

	drv_spb16ch_board_disable_all

        local a=SPB16CH"$board_id"_GPIO
        local gpio_n=${!a}

        echo "** drv_spb16ch_board_enable() - Enable board: $board_id - gpio $gpio_n"
        $GPIO -g write $gpio_n $SPB16CH_GPIO_ON

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

