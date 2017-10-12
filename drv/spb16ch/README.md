# Driver per controllare la scheda "Smart Power Board 16 channel with RTC" (spb16ch)

Questo driver richiede l'interprete python e la libreria python-smbus. Inoltre l'utente pi deve fare parte del gruppo i2c

sudo apt-get install python python-smbus
sudo usermod -a -G i2c pi

Oltre a quanto sopra indicato, il raspberry deve avere caricato i moduli di gestione del bus i2c:
sudo raspi-config
Interfacing Options / I2C / Yes

Per maggiori informazioni consulta https://www.lejubila.net/2017/10/pigarden-spb16ch-gestiamo-fino-a-128-zone-nel-nostro-impianto-di-irrigazione/
