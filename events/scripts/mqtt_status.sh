#!/bin/bash
EVENT="$1"
CAUSE="$2"
DATE="$3"
DIR_SCRIPT=`dirname $0`
"$DIR_SCRIPT/../../piGarden.sh" mqtt_status #&>> /tmp/pigarden_mqtt.log
