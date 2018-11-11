#
# Questa funzione viene invocata dalla funzione "setup_drv" di piGarden ad ogni avvio dello script
# e serve per eseguire l'eventuale setup del driver se necessario
#
function drv_rainsensorqty_setup {

	declare -g RAINSENSORQTY_FILE_RUN
	RAINSENSORQTY_FILE_RUN="$STATUS_DIR/rainsensorqty_run"

}

