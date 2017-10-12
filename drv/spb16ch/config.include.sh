#
# Mapping rele spb16ch: l'indice indica il relè, ogni elemento deve essere lungo 8 caratteri, 
# 1-2: i primi due indicano l'indirizzo della scheda
# 3-3: separatore
# 4-4: il quarto carattere indica il mux channel
# 5-5: separatore
# 6-8: dal 6 all'ottavo carattere indicano il numero del rele sul canale
# 10-10: l'ultimo carattere indica il numero identificativo della scheda spb16ch

# Scheda 1 - address 70h - GS1:chiuso, GS2:chiuso, GS3:chiuso
SPB16CH_RELE_MAP[1]="70|0|  1|1"
SPB16CH_RELE_MAP[2]="70|0|  2|1"
SPB16CH_RELE_MAP[3]="70|0|  4|1"
SPB16CH_RELE_MAP[4]="70|0|  8|1"
SPB16CH_RELE_MAP[5]="70|0| 16|1"
SPB16CH_RELE_MAP[6]="70|0| 32|1"
SPB16CH_RELE_MAP[7]="70|0| 64|1"
SPB16CH_RELE_MAP[8]="70|0|128|1"
SPB16CH_RELE_MAP[9]="70|1|  1|1"
SPB16CH_RELE_MAP[10]="70|1|  2|1"
SPB16CH_RELE_MAP[11]="70|1|  4|1"
SPB16CH_RELE_MAP[12]="70|1|  8|1"
SPB16CH_RELE_MAP[13]="70|1| 16|1"
SPB16CH_RELE_MAP[14]="70|1| 32|1"
SPB16CH_RELE_MAP[15]="70|1| 64|1"
SPB16CH_RELE_MAP[16]="70|1|128|1"

# Scheda 2 - address 71h - GS1:aperto, GS2:chiuso, GS3:chiuso
SPB16CH_RELE_MAP[17]="71|0|  1|2"
SPB16CH_RELE_MAP[18]="71|0|  2|2"
SPB16CH_RELE_MAP[19]="71|0|  4|2"
SPB16CH_RELE_MAP[20]="71|0|  8|2"
SPB16CH_RELE_MAP[21]="71|0| 16|2"
SPB16CH_RELE_MAP[22]="71|0| 32|2"
SPB16CH_RELE_MAP[23]="71|0| 64|2"
SPB16CH_RELE_MAP[24]="71|0|128|2"
SPB16CH_RELE_MAP[25]="71|1|  1|2"
SPB16CH_RELE_MAP[26]="71|1|  2|2"
SPB16CH_RELE_MAP[27]="71|1|  4|2"
SPB16CH_RELE_MAP[28]="71|1|  8|2"
SPB16CH_RELE_MAP[29]="71|1| 16|2"
SPB16CH_RELE_MAP[30]="71|1| 32|2"
SPB16CH_RELE_MAP[31]="71|1| 64|2"
SPB16CH_RELE_MAP[32]="71|1|128|2"

# Scheda 3 - address 72h - GS1:chiuso, GS2:aperto, GS3:chiuso
SPB16CH_RELE_MAP[33]="72|0|  1|3"
SPB16CH_RELE_MAP[34]="72|0|  2|3"
SPB16CH_RELE_MAP[35]="72|0|  4|3"
SPB16CH_RELE_MAP[36]="72|0|  8|3"
SPB16CH_RELE_MAP[37]="72|0| 16|3"
SPB16CH_RELE_MAP[38]="72|0| 32|3"
SPB16CH_RELE_MAP[39]="72|0| 64|3"
SPB16CH_RELE_MAP[40]="72|0|128|3"
SPB16CH_RELE_MAP[41]="72|1|  1|3"
SPB16CH_RELE_MAP[42]="72|1|  2|3"
SPB16CH_RELE_MAP[43]="72|1|  4|3"
SPB16CH_RELE_MAP[44]="72|1|  8|3"
SPB16CH_RELE_MAP[45]="72|1| 16|3"
SPB16CH_RELE_MAP[46]="72|1| 32|3"
SPB16CH_RELE_MAP[47]="72|1| 64|3"
SPB16CH_RELE_MAP[48]="72|1|128|3"

# Scheda 4 - address 73h - GS1:aperto, GS2:aperto, GS3:chiuso
SPB16CH_RELE_MAP[49]="73|0|  1|4"
SPB16CH_RELE_MAP[50]="73|0|  2|4"
SPB16CH_RELE_MAP[51]="73|0|  4|4"
SPB16CH_RELE_MAP[52]="73|0|  8|4"
SPB16CH_RELE_MAP[53]="73|0| 16|4"
SPB16CH_RELE_MAP[54]="73|0| 32|4"
SPB16CH_RELE_MAP[55]="73|0| 64|4"
SPB16CH_RELE_MAP[56]="73|0|128|4"
SPB16CH_RELE_MAP[57]="73|1|  1|4"
SPB16CH_RELE_MAP[58]="73|1|  2|4"
SPB16CH_RELE_MAP[59]="73|1|  4|4"
SPB16CH_RELE_MAP[60]="73|1|  8|4"
SPB16CH_RELE_MAP[61]="73|1| 16|4"
SPB16CH_RELE_MAP[62]="73|1| 32|4"
SPB16CH_RELE_MAP[63]="73|1| 64|4"
SPB16CH_RELE_MAP[64]="73|1|128|4"

# Scheda 5 - address 74h - GS1:chiuso, GS2:chiuso, GS3:aperto
SPB16CH_RELE_MAP[65]="74|0|  1|5"
SPB16CH_RELE_MAP[66]="74|0|  2|5"
SPB16CH_RELE_MAP[67]="74|0|  4|5"
SPB16CH_RELE_MAP[68]="74|0|  8|5"
SPB16CH_RELE_MAP[69]="74|0| 16|5"
SPB16CH_RELE_MAP[70]="74|0| 32|5"
SPB16CH_RELE_MAP[71]="74|0| 64|5"
SPB16CH_RELE_MAP[72]="74|0|128|5"
SPB16CH_RELE_MAP[73]="74|1|  1|5"
SPB16CH_RELE_MAP[74]="74|1|  2|5"
SPB16CH_RELE_MAP[75]="74|1|  4|5"
SPB16CH_RELE_MAP[76]="74|1|  8|5"
SPB16CH_RELE_MAP[77]="74|1| 16|5"
SPB16CH_RELE_MAP[78]="74|1| 32|5"
SPB16CH_RELE_MAP[79]="74|1| 64|5"
SPB16CH_RELE_MAP[80]="74|1|128|5"

# Scheda 6 - address 75h - GS1:aperto, GS2:chiuso, GS3:aperto
SPB16CH_RELE_MAP[81]="75|0|  1|6"
SPB16CH_RELE_MAP[82]="75|0|  2|6"
SPB16CH_RELE_MAP[83]="75|0|  4|6"
SPB16CH_RELE_MAP[84]="75|0|  8|6"
SPB16CH_RELE_MAP[85]="75|0| 16|6"
SPB16CH_RELE_MAP[86]="75|0| 32|6"
SPB16CH_RELE_MAP[87]="75|0| 64|6"
SPB16CH_RELE_MAP[88]="75|0|128|6"
SPB16CH_RELE_MAP[89]="75|1|  1|6"
SPB16CH_RELE_MAP[90]="75|1|  2|6"
SPB16CH_RELE_MAP[91]="75|1|  4|6"
SPB16CH_RELE_MAP[92]="75|1|  8|6"
SPB16CH_RELE_MAP[93]="75|1| 16|6"
SPB16CH_RELE_MAP[94]="75|1| 32|6"
SPB16CH_RELE_MAP[95]="75|1| 64|6"
SPB16CH_RELE_MAP[96]="75|1|128|6"

# Scheda 7 - address 76h - GS1:chiuso, GS2:aperto, GS3:aperto
SPB16CH_RELE_MAP[97]="76|0|  1|7"
SPB16CH_RELE_MAP[98]="76|0|  2|7"
SPB16CH_RELE_MAP[99]="76|0|  4|7"
SPB16CH_RELE_MAP[100]="76|0|  8|7"
SPB16CH_RELE_MAP[101]="76|0| 16|7"
SPB16CH_RELE_MAP[102]="76|0| 32|7"
SPB16CH_RELE_MAP[103]="76|0| 64|7"
SPB16CH_RELE_MAP[104]="76|0|128|7"
SPB16CH_RELE_MAP[105]="76|1|  1|7"
SPB16CH_RELE_MAP[106]="76|1|  2|7"
SPB16CH_RELE_MAP[107]="76|1|  4|7"
SPB16CH_RELE_MAP[108]="76|1|  8|7"
SPB16CH_RELE_MAP[109]="76|1| 16|7"
SPB16CH_RELE_MAP[110]="76|1| 32|7"
SPB16CH_RELE_MAP[111]="76|1| 64|7"
SPB16CH_RELE_MAP[112]="76|1|128|7"

# Scheda 8 - address 77h - GS1:aperto, GS2:aperto, GS3:aperto
SPB16CH_RELE_MAP[113]="77|0|  1|8"
SPB16CH_RELE_MAP[114]="77|0|  2|8"
SPB16CH_RELE_MAP[115]="77|0|  4|8"
SPB16CH_RELE_MAP[116]="77|0|  8|8"
SPB16CH_RELE_MAP[117]="77|0| 16|8"
SPB16CH_RELE_MAP[118]="77|0| 32|8"
SPB16CH_RELE_MAP[119]="77|0| 64|8"
SPB16CH_RELE_MAP[120]="77|0|128|8"
SPB16CH_RELE_MAP[121]="77|1|  1|8"
SPB16CH_RELE_MAP[122]="77|1|  2|8"
SPB16CH_RELE_MAP[123]="77|1|  4|8"
SPB16CH_RELE_MAP[124]="77|1|  8|8"
SPB16CH_RELE_MAP[125]="77|1| 16|8"
SPB16CH_RELE_MAP[126]="77|1| 32|8"
SPB16CH_RELE_MAP[127]="77|1| 64|8"
SPB16CH_RELE_MAP[128]="77|1|128|8"

# Array contenente i gli identificativi delle schede usate
declare -g -a SPB16CH_USED_ID
SPB16CH_USED_ID=()

# Nome del file dove memorizzare gli id delle schede utilizzate
declare -g SPB16CH_BOARD_ID_STORE_FILE
SPB16CH_BOARD_ID_STORE_FILE="$STATUS_DIR/spb16ch_board_id_store"
