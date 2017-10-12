#
# Questa funzione viene inviocata dalla funzione "setup_drv" ad ogni avvio di piGarden
# esegue il setup del driver recuperando gli identificativi delle schede sbp16ch usati
#
function drv_spb16ch_setup {

	drv_spb16ch_boards_id_load
	echo "*********** drv_spb16ch_setup: identificativi schede caricati: ${SPB16CH_USED_ID[@]}"

}


