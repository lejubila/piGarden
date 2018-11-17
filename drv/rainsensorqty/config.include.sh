#
# File di configurazione del driver
# 

declare -g RAINSENSORQTY_LASTRAIN
RAINSENSORQTY_LASTRAIN="$STATUS_DIR/rainsensorqty_lastrain"

declare -g RAINSENSORQTY_LOG
RAINSENSORQTY_LOG="$DIR_SCRIPT/log/rainsensorqty.log"

declare -g RAINSENSORQTY_PID
RAINSENSORQTY_MONPID="$TMP_PATH/rainsensorqty_monitor.pid"

declare -g RAINSENSORQTY_DIR
RAINSENSORQTY_DIR="$DIR_SCRIPT/drv/rainsensorqty"

declare -g RAINSENSORQTY_PULSE
RAINSENSORQTY_PULSE=falling

declare -g RAINSENSORQTY_WAIT
RAINSENSORQTY_WAIT=rising
