function setup_drv { 

	declare -a list_drv
	list_drv=()

        # Inizializza i driver per le elettrovalvole
        for i in $(seq $EV_TOTAL)
        do
                local a=EV"$i"_GPIO
                local gpio="${!a}"
		if [[ "$gpio" == drv:* ]]; then
			local drv=`echo $gpio | $CUT -d':' -f2,2`
			if [[ ! " ${list_drv[@]} " =~ " ${drv} " ]]; then
				list_drv+=("$drv")
			fi
		fi
        done



	local file_drv
	for drv in "${list_drv[@]}"
	do
		for callback in init open close status
		do
			file_drv="$DIR_SCRIPT/drv/$drv/$callback.include.sh"
			if [ -f "$file_drv" ]; then
				. "$file_drv"
			fi
		done
	done

}
