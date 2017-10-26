#!/bin/bash
#
# Send mail on triggered event
#
# $1 = event
EVENT="$1"
P2="$2"
P3="$3"
P4="$4"
P5="$5"

echo "testevent break $(date) $EVENT $P2 $P3 $P4 $P5" >> /tmp/piGarden.testevent

exit 1
