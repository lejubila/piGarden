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
SUBJECT="piGarden notification mail: event $EVENT"
BODY=""

case "$EVENT" in
	"init_before" | "init_after")
		STATE="$2"
		TIME=$3
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nTIME: $(/bin/date -d@$TIME)"
		;;

	"ev_open_before" | "ev_open_after")
		ALIAS="$2"
		FORCE="$3"
		TIME=$4
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nZONE: $ALIAS\nFORCED IRRIGATION: $FORCE\nTIME: $(/bin/date -d@$TIME)"
		;;

	"ev_close_before" | "ev_close_after")
		ALIAS="$2"
		TIME=$3
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nZONE: $ALIAS\nTIME: $(/bin/date -d@$TIME)"
		;;

	"check_rain_sensor_before" | "check_rain_sensor_after" | "check_rain_sensor_change")
		STATE="$2"
		TIME=$3
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nSTATE: $ALIAS\nTIME: $(/bin/date -d@$TIME)"
		;;

	"check_rain_online_before" | "check_rain_online_after" | "check_rain_online_change")
		STATE="$2"
		TIME=$3
		BODY="PiGarden triggered new event\n\nEVENT: $EVENT\nSTATE: $ALIAS\nTIME: $(/bin/date -d@$TIME)"
		;;

	*)
		exit
		;;

esac

echo -e "$BODY" | /usr/bin/mail -s "$SUBJECT" $TO -r $FROM &

