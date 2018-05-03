#!/bin/bash
#
# Send mail on triggered event
#
# $1 = event
# $2 = cause
# $3 = time
#
# To send an email with this script you must install and configure ssmtp and mailutils:
# sudo apt-get install ssmtp mailutils
#
# edit the configuration file /etc/ssmtp/ssmtp.conf and insert the below lines:
#
# root=postmaster
# mailhub=smtp.gmail.com:587
# hostname=guard
# FromLineOverride=YES
# AuthUser=your_mail@gmail.com
# AuthPass=your_password
# UseSTARTTLS=YES
#

EVENT="$1"

TO="mail@destination.com"
FROM="piGarden@your_domain.com"
SUBJECT="[piGarden notification mail] event $EVENT"
BODY=""

case "$EVENT" in
	"init_before" | "init_after")
		TIME=$2
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nTIME: $(/bin/date -d@$TIME)"
		;;

	"ev_open_before" | "ev_open_after")
		ALIAS="$2"
		FORCE="$3"
		TIME=$4
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nZONE: $ALIAS\nFORCED IRRIGATION: $FORCE\nTIME: $(/bin/date -d@$TIME)"
		;;

	"ev_open_in_before")
		ALIAS="$2"
		FORCE="$3"
		MINUTE_START="$4"
		MINUTE_STOP="$5"
		TIME=$6
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nZONE: $ALIAS\nFORCED IRRIGATION: $FORCE\nMINUTE START: $MINUTE_START\nMINUTE STOP: $MINUTE_STOP\nTIME: $(/bin/date -d@$TIME)"
		;;

	"ev_open_in_after")
		ALIAS="$2"
		FORCE="$3"
		CRON_START="$4"
		CRON_STOP="$5"
		TIME=$6
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nZONE: $ALIAS\nFORCED IRRIGATION: $FORCE\nCRON START: $CRON_START\nCRON STOP: $CRON_STOP\nTIME: $(/bin/date -d@$TIME)"
		;;


	"ev_close_before" | "ev_close_after")
		ALIAS="$2"
		TIME=$3
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nZONE: $ALIAS\nTIME: $(/bin/date -d@$TIME)"
		;;

	"ev_not_open_for_rain" | "ev_not_open_for_rain_online" | "ev_not_open_for_rain_sensor")
		ALIAS="$2"
		TIME=$3
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nZONE: $ALIAS\nTIME: $(/bin/date -d@$TIME)"
		;;

	"check_rain_sensor_before" | "check_rain_sensor_after" | "check_rain_sensor_change")
		STATE="$2"
		TIME=$3
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nSTATE: $STATE\nTIME: $(/bin/date -d@$TIME)"
		;;

	"check_rain_online_before")
		STATE="$2"
		TIME=$3
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nSTATE: $STATE\nTIME: $(/bin/date -d@$TIME)"
		;;

	"check_rain_online_after" | "check_rain_online_change")
		STATE="$2"
		WEATHER="$3"
		TIME=$4
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nSTATE: $STATE\nWEATHER: $WEARTHER\nTIME: $(/bin/date -d@$TIME)"
		;;

	"cron_add_before" | "cron_add_after")
		CRON_TYPE="$2"
		CRON_ARG="$3"
		CRON_ELEMENT="$4"
		TIME=$5
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nCRON TYPE: $CRON_TYPE\nCRON ARG: $CRON_ARG\nCRON ELEMENT: $CRON_ELEMENT\nTIME: $(/bin/date -d@$TIME)"
		;;

	"cron_del_before" | "cron_del_after")
		CRON_TYPE="$2"
		CRON_ARG="$3"
		TIME=$4
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nCRON TYPE: $CRON_TYPE\nCRON ARG: $CRON_ARG\nTIME: $(/bin/date -d@$TIME)"
		;;

	"exec_poweroff_before" | "exec_poweroff_after" | "exec_reboot_before" | "exec_reboot_after")
		TIME=$2
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nTIME: $(/bin/date -d@$TIME)"
		;;

	*)
		exit
		;;

esac

echo -e "$BODY" | /usr/bin/mail -s "$SUBJECT" $TO -r $FROM &

