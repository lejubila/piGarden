#!/bin/bash
#
# Send mail on triggered event
#
# $1 = event
# $2 = cause
# $3 = time
#
# To send an email with this script you must install telegram-cli @see http://tuxmaniacs.it/2015/01/installare-telegram-sul-raspberry-pi.html
#

EVENT="$1"
CAUSE="$2"
TIME=$3

TG_CLI="/home/pi/tg/bin/telegram-cli"

TO="Your_Destination_Contact"

CMD="msg $TO \"piGuardian triggered new event\\n\\nEVENT: $EVENT\\nCAUSE: $CAUSE\\nTIME: $(/bin/date -d@$TIME)\""
(sleep 1; echo "contact_list"; sleep 1; echo $CMD) | $TG_CLI -W
