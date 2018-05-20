#
# Questa funzione viene invocata dalla funzione "setup_drv" di piGarden ad ogni avvio dello script
# e serve per eseguire l'eventuale setup del driver se necessario
#
function drv_remote_setup {

	local all_remote=0

        # Imposta le zone come remote 
        for i in $(seq $EV_TOTAL)
        do
                local a=EV"$i"_GPIO
                local gpio="${!a}"
                if [[ "$gpio" == drv:remote:* ]]; then
		        local varname=EV"$i"_REMOTE
			declare -g $varname=1
			all_remote=$((all_remote+1))
		fi
        done

	# Se tutte le zone sono remote disabilita la gestione dell'alimentazione bistabile
	if [ $all_remote -eq $EV_TOTAL ]; then
		EV_MONOSTABLE=1
	fi

}

