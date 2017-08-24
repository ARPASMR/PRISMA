# PRISMA
Il processo esegue il calcolo della cumulata oraria dai dati radar MeteoCH.
Il codice è parte del container _prisma_ nel repository interno di ARPA Lombardia.
L'immagine è interamente costruita con _Dockerfile_, compresa la parte di compilazione del file cumula_ora.c. Pertanto, eventuali modifiche agli script o al codice vengono interamente trasferiti nell'immagine.
Il comando per eseguire il container è il seguente:
    docker run -it --rm -v /home/meteo/dati/prisma/cumulata:/prisma/cumulata registry.arpa.local/processi/prisma /bin/bash ./prisma.sh
**NOTA BENE**
questo comando è quello che viene lanciato da una macchina dello swarm di test (es. 10.10.99.136).

# TODO 
vedi issues
