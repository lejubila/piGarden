#!/usr/bin/python
# coding=utf-8

# Write the eeprom 24C16
# I2C Address: 0x50 (24C16)
# sudo ./ee_write.py 0x50 address data
# Example: sudo ./ee_write.py 50 0 1

import time
import argparse

import RPi.GPIO as GPIO
import smbus

def I2C_setup(i2c_address, eeprom_address, eeprom_data):
    I2C_address = 0x50
    if GPIO.RPI_REVISION in [2, 3]:
        I2C_bus_number = 1
    else:
        I2C_bus_number = 0
    bus = smbus.SMBus(I2C_bus_number)
    bus.write_byte_data(I2C_address, eeprom_address, eeprom_data)

def menu():
    parser = argparse.ArgumentParser(description='Select address and data to write on eeprom 24C16 ')
    parser.add_argument('i2c_address', type=int)
    parser.add_argument('eeprom_address', type=int)
    parser.add_argument('eeprom_data', type=int)

    args = parser.parse_args()

    I2C_setup(args.i2c_address, args.eeprom_address, args.eeprom_data)

if __name__ == "__main__":
    menu()
