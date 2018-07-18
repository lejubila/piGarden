#
# Installare libreria paho-mqtt, configparser:
# sudo pip install paho-mqtt configparser
#

import paho.mqtt.client as mqttClient
import time
import subprocess
import configparser

def on_connect(client, userdata, flags, rc):

    if rc == 0:

        print("Connected to broker")

        global Connected                # Use global variable
        Connected = True                # Signal connection 

    else:

        print("Connection failed")

def on_message(client, userdata, message):
    print "Topic           : "  + message.topic
    print "Message received: "  + message.payload
    if message.topic.startswith("pigarden/command/"):
        print "pigarden command: " + message.payload
        cmd = ""
        cmd = message.payload
        if pigarden_user != "" and pigarden_pwd != "":
            cmd = pigarden_user + '\n' + pigarden_pwd + '\n' + cmd 
        
        p = subprocess.Popen([ pigarden_path + "mqttconnector/exec_command.sh", cmd ], stdout=subprocess.PIPE)
        (output, err) = p.communicate()
        
        ## Wait for date to terminate. Get return returncode ##
        p_status = p.wait()
        print "Command : '" + cmd + "'"
        print "Command output : ", output
        print "Command exit status/return code : ", p_status




config = configparser.ConfigParser()
config.read('/etc/piGardenMqttconnector.ini')


Connected = False   # global variable for the state of the connection

broker_address = config['mqtt']['broker_address']
port = int(config['mqtt']['port'])
user = config['mqtt']['user']
password = config['mqtt']['password']
client_id = config['mqtt']['client_id']

pigarden_path = config['pigarden']['path']
pigarden_user = config['pigarden']['user']
pigarden_pwd = config['pigarden']['pwd']

client = mqttClient.Client(client_id)              # create new instance
client.username_pw_set(user, password=password)    # set username and password
client.on_connect = on_connect                      # attach function to callback
client.on_message = on_message                      # attach function to callback

print broker_address, port, user, password

client.connect(broker_address, port=port)          # connect to broker

client.loop_start()        #start the loop

while Connected != True:    #Wait for connection
    time.sleep(0.1)

client.subscribe("pigarden/command/+")

try:
    while True:
        time.sleep(1)

except KeyboardInterrupt:
    print "exiting"
    client.disconnect()
    client.loop_stop()



