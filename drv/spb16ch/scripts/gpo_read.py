#!/usr/bin/python
# coding=utf-8

# Select address and channel of PCA9571 I2C general purpose outputs
# I2C Address: 0x25 Fixed
# sudo ./gpo_read.py CHANNEL
# Example: sudo ./gpo_read.py 25

import time
import argparse

import RPi.GPIO as GPIO
import smbus

def I2C_read(multiplexer_i2c_address):
    I2C_address = 0x25
    if GPIO.RPI_REVISION in [2, 3]:
        I2C_bus_number = 1
    else:
        I2C_bus_number = 0

    bus = smbus.SMBus(I2C_bus_number)
    status_outputs=bus.read_byte(I2C_address)
    time.sleep(0)
#    print("PCA9571 sts:{}".format(bin(bus.read_byte(I2C_address))))
    print("PCA9571 GPO sts:{}".format(hex(bus.read_byte(I2C_address))))

def menu():

    I2C_read(0x25)

if __name__ == "__main__":
    menu()
