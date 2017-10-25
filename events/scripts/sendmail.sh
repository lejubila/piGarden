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
CAUSE="$2"
TIME=$3

TO="mail@destination.com"
FROM="piGuardian@your_domain.com"
SUBJECT="piGuardian notification mail: $EVENT"

echo -e "PiGuardian triggered new event\n\nEVENT: $EVENT\nCAUSE: $CAUSE\nTIME: $(/bin/date -d@$TIME)" | /usr/bin/mail -s "$SUBJECT" $TO -r $FROM -A /home/pi/piGuardian/log/piGuardian.log
