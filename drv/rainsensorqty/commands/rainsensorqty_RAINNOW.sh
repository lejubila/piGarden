#!/bin/bash
# Driver rainsensorqty - driver for measure the rain volume
# Author: androtto
# file "rainsensorqty_RAINNOW.sh"
# test script for simulate rain ... now!
# Version: 0.2.0a
# Data: 13/Aug/2019

SCRIPTDIR="$(cd `dirname $0` ; pwd )"
SCRIPTNAME=${0##*/}
cd $SCRIPTDIR/.. # command is a subdirectory of driver

DIR_SCRIPT=/home/pi/piGarden # home directory of piGarden
CONFIG_ETC="/etc/piGarden.conf"
. $CONFIG_ETC

. ./config.include.sh
. ./common.include.sh
. ./init.include.sh
. ./rainsensor.include.sh

echo "RAIN now!"
echo "$(date +%s):$RAINSENSORQTY_LOOPSFORSETRAINING" > ${RAINSENSORQTY_LASTRAIN}
echo "file ${RAINSENSORQTY_LASTRAIN} updated."
echo -e "\nLAST RAIN:"
cat $RAINSENSORQTY_LASTRAIN | rain_when_amount
