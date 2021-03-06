#!/usr/bin/python
# coding=utf-8

# Select address and channel of PCA9571 I2C general purpose outputs
# I2C Address: 0x25 Fixed
# sudo ./gpo_active.py CHANNEL
# Example: sudo ./gpo_active.py 25 255 1 #all relays activates

import time
import argparse

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

file = open("rl1", "r")
address=int(file.readline())
channel_outputs=int(file.readline())
state=int(file.readline())

def menu():
    I2C_setup(address, channel_outputs, state)

if __name__ == "__main__":
    menu()
