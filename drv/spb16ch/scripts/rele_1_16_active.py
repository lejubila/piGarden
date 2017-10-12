#!/usr/bin/python
# coding=utf-8

# Select address and channel of PCA9571 I2C general purpose outputs
# I2C Address: 0x25 Fixed
# sudo ./gpo_active.py CHANNEL
# Example: sudo ./gpo_active.py 25 255 1 #all relays activates

import time
import argparse
import subprocess

import RPi.GPIO as GPIO
import smbus


def I2C_setup(multiplexer_i2c_address, i2c_channel_setup, state):
    I2C_address = 0x25
    if GPIO.RPI_REVISION in [2, 3]:
        I2C_bus_number = 1
    else:
        I2C_bus_number = 0

    bus = smbus.SMBus(I2C_bus_number)
    status_outputs=bus.read_byte(I2C_address)
    if state == 1:
      i2c_channel_setup=status_outputs|i2c_channel_setup
    elif state == 0:
      i2c_channel_setup=(-i2c_channel_setup-1)&status_outputs
    elif state == -1:
      i2c_channel_setup=0
    bus.write_byte(I2C_address, i2c_channel_setup)
    #time.sleep(0)


def menu():
    while 1==1:
	subprocess.call('./mux_channel.py 72 0', shell=True)
        #time.sleep(0.1)
	file = open("rele1_16", "r")
	address=int(file.readline())
	channel_outputs1=int(file.readline())
	state1=int(file.readline())
	channel_outputs2=int(file.readline())
	state2=int(file.readline())
	channel_outputs3=int(file.readline())
	state3=int(file.readline())
	channel_outputs4=int(file.readline())
	state4=int(file.readline())
	channel_outputs5=int(file.readline())
	state5=int(file.readline())
	channel_outputs6=int(file.readline())
	state6=int(file.readline())
	channel_outputs7=int(file.readline())
	state7=int(file.readline())
	channel_outputs8=int(file.readline())
	state8=int(file.readline())
	channel_outputs9=int(file.readline())
	state9=int(file.readline())
	channel_outputs10=int(file.readline())
	state10=int(file.readline())
	channel_outputs11=int(file.readline())
	state11=int(file.readline())
	channel_outputs12=int(file.readline())
	state12=int(file.readline())
	channel_outputs13=int(file.readline())
	state13=int(file.readline())
	channel_outputs14=int(file.readline())
	state14=int(file.readline())
	channel_outputs15=int(file.readline())
	state15=int(file.readline())
	channel_outputs16=int(file.readline())
	state16=int(file.readline())
    	I2C_setup(address, channel_outputs1, state1)
    	I2C_setup(address, channel_outputs2, state2)
    	I2C_setup(address, channel_outputs3, state3)
    	I2C_setup(address, channel_outputs4, state4)
    	I2C_setup(address, channel_outputs5, state5)
    	I2C_setup(address, channel_outputs6, state6)
    	I2C_setup(address, channel_outputs7, state7)
    	I2C_setup(address, channel_outputs8, state8)
	subprocess.call('./mux_channel.py 72 1', shell=True)
        #time.sleep(0.1)
    	I2C_setup(address, channel_outputs9, state9)
    	I2C_setup(address, channel_outputs10, state10)
    	I2C_setup(address, channel_outputs11, state11)
    	I2C_setup(address, channel_outputs12, state12)
    	I2C_setup(address, channel_outputs13, state13)
    	I2C_setup(address, channel_outputs14, state14)
    	I2C_setup(address, channel_outputs15, state15)
    	I2C_setup(address, channel_outputs16, state16)
	subprocess.call('./mux_channel.py 72 0', shell=True)

if __name__ == "__main__":
    menu()
