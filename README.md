# piGarden

Bash script to manage an irrigation system built with a Raspberry Pi

## Official documentation 

Documentation of piGarden and build system irrigation with Raspberry Pi can be found on the [www.lejubila.net/tag/pigarden/](http://www.lejubila.net/tag/pigarden/)

## License

This script is open-sourced software under GNU GENERAL PUBLIC LICENSE Version 2

## Installation to Raspbian Jessie

1) Installs the necessary packages on your terminal:

``` bash
sudo apt-get install git curl gzip grep sed ucspi-tcp
```

2) Compile and install Jq (commandline JSON processor):

``` bash
cd 
sudo apt-get install flex -y 
sudo apt-get install bison -y 
sudo apt-get install gcc -y 
sudo apt-get install make -y 
sudo apt-get install libtool autoconf automake gettext autotools-dev -y 
sudo apt-get install dh-autoreconf -y 
wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-1.5.tar.gz
tar xfvz jq-1.5.tar.gz
cd jq-1.5
autoreconf -i
./configure --disable-maintainer-mode
make
sudo make install
```

3) Compile and install gpio program from WiringPi package:

``` bash
cd
git clone git://git.drogon.net/wiringPi
cd wiringPi
git pull origin 
./build
```

4) Download and install piGarden in your home

``` bash
cd
git clone https://github.com/lejubila/piGarden.git
```

## Configuration

Copy configuration file in /etc

```bash
cd
sudo cp piGarden/conf/piGarden.conf.example /etc/piGarden.conf
```

Customize the configuration file. 
For more information see 
[www.lejubila.net/2015/12/impianto-di-irrigazione-con-raspberry-pi-pigarden-lo-script-di-gestione-quinta-parte/](https://www.lejubila.net/2015/12/impianto-di-irrigazione-con-raspberry-pi-pigarden-lo-script-di-gestione-quinta-parte/)
and
[www.lejubila.net/2017/04/pigarden-0-2-easter-egg/](https://www.lejubila.net/2017/04/pigarden-0-2-easter-egg/)
