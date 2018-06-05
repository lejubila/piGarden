# Driver for controlling Sonoff remote relays with Tasmota firmware via http protocol

More information on Sonoff Tasmota firmware: https://github.com/arendst/Sonoff-Tasmota


# Example of zone configuration in piGarden.conf

```EV1_ALIAS="Giardino_Posteriore_DX"
EV1_GPIO="drv:sonoff_tasmota_http:SONOFF1:Power1"
EV1_MONOSTABLE=1

EV2_ALIAS="Giardino_Posteriore_CN"
EV2_GPIO="drv:sonoff_tasmota_http:SONOFF1:Power2"
EV2_MONOSTABLE=1

SONOFF1_IP="192.168.1.1"
SONOFF1_USER="user"
SONOFF1_PWD="pwd"
```
More information for configuration: https://www.lejubila.net/2018/06/pigarden-0-5-7-gestisci-le-tue-elettrovalvole-con-i-moduli-sonoff-grazie-al-nuovo-driver-sonoff_tasmota_http

