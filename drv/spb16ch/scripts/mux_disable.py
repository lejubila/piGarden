#!/usr/bin/python
# coding=utf-8

# Disable PCA9547 I2C multiplexer
# I2C Address: 0xYY, where YY can be 70 through 77
# sudo ./mux_channel.py ADDRESS CHANNEL
# Example: sudo ./mux_disable.py 70 

import time
import argparse

import RPi.GPIO as GPIO
import smbus

def I2C_setup(multiplexer_i2c_address):
    I2C_address = 0x70 + multiplexer_i2c_address % 10
    if GPIO.RPI_REVISION in [2, 3]:
        I2C_bus_number = 1
    else:
        I2C_bus_number = 0

    bus = smbus.SMBus(I2C_bus_number)
    i2c_channel_setup=0x00 
    #i2c_channel_setup=i2c_channel_setup + 0x08 
    bus.write_byte(I2C_address, i2c_channel_setup)
    #time.sleep(0.1)

def menu():
    parser = argparse.ArgumentParser(description='Select Address of Disable PCA9547 Multiplexer')
    parser.add_argument('address', type=int)

    args = parser.parse_args()

    I2C_setup(args.address)

if __name__ == "__main__":
    menu()
