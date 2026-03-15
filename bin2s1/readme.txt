Python script und C-Code für die Umwandlung einer Binärdatei in Motorola s-record
erzeugt mit Hilfe von Grog am 25.02.2026

bin2s1:
Variante für 2 Adressbytes (8-bit Systeme)
./bin2s1.py test.bin test.s19 0x6000
oder
./bin2s1 test.bin test.s19 0x6000

bin_2_s19:
Variante für 4 Adressbytes

C-Code in ausführbare Datei compilieren
gcc -o bin2s19 bin2s19.c
