#!/bin/bash
#
# Send telegram notificacion on triggered event
#
# $1 = event
# $2 = cause
# $3 = time
#
# To use this script, you must get your hash. Register for the rpinotify service. Get the hash and enter it below
#

# rpinotify token
TOKEN=""

EVENT="$1"

TO="mail@destination.com"
FROM="piGarden@your_domain.com"
SUBJECT="[piGarden notification mail] event $EVENT"
BODY=""

case "$EVENT" in
	"init_before" | "init_after")
		TIME=$2
		BODY="PiGarden triggered new event --- EVENT: $EVENT --- TIME: $(/bin/date -d@$TIME)"
		;;

	"ev_open_before" | "ev_open_after")
		ALIAS="$2"
		FORCE="$3"
		TIME=$4
		BODY="PiGarden triggered new event --- EVENT: $EVENT --- ZONE: $ALIAS --- FORCED IRRIGATION: $FORCE --- TIME: $(/bin/date -d@$TIME)"
		;;

	"ev_open_in_before")
		ALIAS="$2"
		FORCE="$3"
		MINUTE_START="$4"
		MINUTE_STOP="$5"
		TIME=$6
		BODY="PiGarden triggered new event --- EVENT: $EVENT --- ZONE: $ALIAS --- FORCED IRRIGATION: $FORCE --- MINUTE START: $MINUTE_START --- MINUTE STOP: $MINUTE_STOP --- TIME: $(/bin/date -d@$TIME)"
		;;

	"ev_open_in_after")
		ALIAS="$2"
		FORCE="$3"
		CRON_START="$4"
		CRON_STOP="$5"
		TIME=$6
		BODY="PiGarden triggered new event --- EVENT: $EVENT --- ZONE: $ALIAS --- FORCED IRRIGATION: $FORCE --- CRON START: $CRON_START --- CRON STOP: $CRON_STOP --- TIME: $(/bin/date -d@$TIME)"
		;;


	"ev_close_before" | "ev_close_after")
		ALIAS="$2"
		TIME=$3
		BODY="PiGarden triggered new event --- EVENT: $EVENT --- ZONE: $ALIAS --- TIME: $(/bin/date -d@$TIME);"
		;;

	"ev_not_open_for_rain" | "ev_not_open_for_rain_online" | "ev_not_open_for_rain_sensor")
		ALIAS="$2"
		TIME=$3
		BODY="PiGarden triggered new event --- EVENT: $EVENT --- ZONE: $ALIAS --- TIME: $(/bin/date -d@$TIME)"
		;;

	"check_rain_sensor_before" | "check_rain_sensor_after" | "check_rain_sensor_change")
		STATE="$2"
		TIME=$3
		BODY="PiGarden triggered new event --- EVENT: $EVENT --- STATE: $STATE --- TIME: $(/bin/date -d@$TIME)"
		;;

	"check_rain_online_before")
		STATE="$2"
		TIME=$3
		BODY="PiGarden triggered new event --- EVENT: $EVENT --- STATE: $STATE --- TIME: $(/bin/date -d@$TIME)"
		;;

	"check_rain_online_after" | "check_rain_online_change")
		STATE="$2"
		WEATHER="$3"
		TIME=$4
		BODY="PiGarden triggered new event --- EVENT: $EVENT --- STATE: $STATE --- WEATHER: $WEARTHER --- TIME: $(/bin/date -d@$TIME)"
		;;

	"cron_add_before" | "cron_add_after")
		CRON_TYPE="$2"
		CRON_ARG="$3"
		CRON_ELEMENT="$4"
		TIME=$5
		BODY="PiGarden triggered new event --- EVENT: $EVENT --- CRON TYPE: $CRON_TYPE --- CRON ARG: $CRON_ARG --- CRON ELEMENT: $CRON_ELEMENT\nTIME: $(/bin/date -d@$TIME)"
		;;

	"cron_del_before" | "cron_del_after")
		CRON_TYPE="$2"
		CRON_ARG="$3"
		TIME=$4
		BODY="PiGarden triggered new event --- EVENT: $EVENT --- CRON TYPE: $CRON_TYPE --- CRON ARG: $CRON_ARG --- TIME: $(/bin/date -d@$TIME)"
		;;

	"exec_poweroff_before" | "exec_poweroff_after" | "exec_reboot_before" | "exec_reboot_after")
		TIME=$2
		BODY="PiGarden triggered new event --- EVENT: $EVENT --- TIME: $(/bin/date -d@$TIME)"
		;;

	*)
		exit
		;;

esac

curl -X POST -F "text=$BODY" https://api.rpinotify.it/message/$TOKEN/
