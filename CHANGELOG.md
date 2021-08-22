# 0.6.4 - xx/xx/2021
- Add support for sensor mi flora
- Add command line: sensor_status, sensor_status_all, sensor_status_set
- Add api command: sensor_status_set

# 0.6.3 - 10/08/2021
- Add command last_rain_sensor_timestamp, last_rain_online_timestamp, reset_last_rain_sensor_timestamp, reset_last_rain_online_timestamp
- Add socket server api for reset_last_rain_sensor_timestamp, reset_last_rain_online_timestamp

# 0.6.2 - 24/04/2021
- Update rainsensorqty driver to version 0.2.5c

# 0.6.1 - 06/09/2020
- Add support for send log to piGardenWeb

# 0.6.0 - 16/05/2020
- Add support for enable all cron fron api
- Update rainsensorqty driver to version 0.2.5b

# 0.5.14 - 24/09/2019
- Updated rainsensorqty driver to version 0.2.3 
- Added api and command for manage piGardenSched scheduling

# 0.5.13 - 12/08/2019
- Added driver rainsensorqty for menage rainfall detection based on quantity

# 0.5.12.1 - 23/06/2019
- Added zip log drver file when exceeding the size limit

# 0.5.12 - 13/11/2018
- Fixed a bug that prevented the publication of the mqtt topic for each event
- Fixed a bug on openweathermap driver which in some cases causes a malformation of the json status and prevented communication with piGardenWeb 

# 0.5.11 - 11/11/2018
- Added ability to disable online weather service by defining WEATHER_SERVICE="none" in the configuration file

# 0.5.10 - 11/11/2018
- Fix bug in single monostable solenodid management caused from wrong variable name EV_IS_MONOSTAVLE

# 0.5.9 - 01/11/2018
- Added mqtt support for publishing status to broker 

# 0.5.8 - 19/07/2018
- Added "openweathermap" driver for impement check weather condition from openweatermap api

# 0.5.7 - 01/06/2018
- Added "sonoff_tasmota_http" driver for interfacin with Sonoff module with Tasmota firmware over http protocol

# 0.5.6 - 04/05/2018
- Added events ev_not_open_for_rain, ev_not_open_for_rain_sensor, ev_not_open_for_rain_online
- Added script rpinotify.sh for notificate events to telegram

# 0.5.5 - 25/03/2018
- Added "remote" driver to control remote pigarden

# 0.5.4 - 13/11/2017
- Fix bad initialization LOG_OUTPUT_DRV_FILE variable if not defined in config file

# 0.5.3 - 19/11/2017
- Fix send parameter on event init_before and init_after
- Added WEATHER argument in check_rain_sensor_after and check_rain_sensor_change event
- Added events cron_add_before, cron_add_after, cron_del_before, cron_del_after, ev_open_in_before, ev_open_in_after, exec_poweroff_before, exec_poweroff_after, exec_reboot_before, exec_reboot_after
- Added to sendmail.sh argument passed form check_rain_sensor_after and check_rain_sensor_change event
- Added to sendmail.sh new events
- Fix wrong state on event script sendmail.sh

# 0.5.2 - 01/11/2017
- Fix problem inconsistent return value in drv_rain_sensor_get
- Fix get parameter in event script sendmail.sh

# 0.5.1 - 28/10/2017
- Added events managemets
- Added support for zones not subject to rainfall (with parameter EVx_NORAIN)

# 0.5.0 - 12/10/2017
- Implemented driver subsystem for interfacing with other board
- Added driver spb16ch for interfacing with "Smart Power Board 16 channel with RTC"
- Added socket server api for close all zones and disable all scheduling
- Implement command and socket server api to perform system shutdown and reboot
- Fix problem with cron management on similar type cron
- Fix bug: in case of rain the weather data were not updated 
- Fix bug: delete the temporary files for managing the socket server messages that were kept on the system
- Change manage of the lock/unlock function for encrase performance (do you need manualy remove the file /var/shm/piGarden.lock or /tmp/piGarden.lock)
- Add kicad electric schemas

## 0.4.4 - 17/06/2017
- Remove lock/unlock from init function for resove bug

## 0.4.3 - 17/06/2017
- Fix path of sed in lock function

## 0.4.2 - 16/06/2017
- Fix another problem on generate installation identifier to sendo for statistic

## 0.4.1 - 14/06/2017
- Fix problem on send identifier installation for statistic

## 0.4.0 - 14/06/2017
- Add credentials support to socket server (define TCPSERVER_USER and TCPSERVER_PWD in your config file)
- Add management lock/unlock for prevent concurrente call to open/close solenoid
- Added the ability to enter an open / close schedule in disabled mode
- Add send statistic information to remote server
- During the initialization function, information on the last rain is no longer removed

## 0.3.1 - 13/05/2017
Add experimental support for monostable solenoid valve:
- define in your config file the variable EV_MONOSTABLE and assign value 1
- if the solenoid valves close instead of opening and vice versa, reverse the values of the RELE_GPIO_CLOSE and RELE_GPIO_OPEN variables in your configuration file

## 0.3.0 - 07/05/2017
- Add command "open_in" for scheduling on the fly the opens/close a solenoid
- Add command "del_cron_open_in" for delete scheduling the fly the opens/close a solenoid
- Add api in socket server for command open_in and delete_cron_open_in
- Fix minor bug on command "open"
- Changed the path of some temporary files to prevent sd card faults

## 0.2.2 - 25/04/2017
- Fix bug: if it's reining, the solenoid valves were also closed even if they were pushed open in "force" mode

## 0.2.1 - 22/04/2017
- Add installation instructions in README.md file  

## 0.2 (Easter egg) - 17/04/2017
- Implementation of socket server for communicate with piGardenWeb  
- Implementation of messages (error, warning, success) passed to piGardenWeb  
- Added many information in json status to be passed to piGardenWeb  
- Added management cron for scheduling open and closed solenoid, for initialize control unit, for rain control  

## 0.1.1 - 24/12/2015 - BugFix
- Fix the problem for 'av_status' parameter

## 0.1 - 18/12/2015 - First release
- First release to piGarden 

