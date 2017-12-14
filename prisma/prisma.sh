#################################################################################
#
# FILE.......: 	prisma.sh
# -------------------------------------------------------------------------------
# PURPOSE....: 	Conversione immagini radar Monte Lema
#		e calcolo cumulata oraria per uso PRISMA
#								
# -------------------------------------------------------------------------------
# CREATED....: 	Dicembre 2011 (Pellegrini, Cremonini)
#
#                  DATE                      DESCRIPTION
# MODIFIED...: 
# marta, 15/04/2016: inserito chiamata syslogger su scp delle elaborazioni
# -------------------------------------------------------------------------------
# VERSION....: 	1.0 (22/12/2011)
#
# =======================================================================
# REFERENCES..:
#
# Pellegrini:   	ARPA Lombardia
#
#################################################################################
#!/bin/bash
echo
echo "******* Inizio script `basename $0` alle ore `date` *****************"

###	lettura variabili ambiente
. /conf/default.conf
. /prisma/variabili_prisma && cat /prisma/variabili_prisma
declare -x LANG="us_US.UTF-8"
export LC_TIME="en_GB"

if [ "$1" == "--help" ]
then
	echo "Utilizzo: $0 <data di inizio cumulazione (formato aaaammgghh, ad esempio 2007061512)>"
	exit
fi

### controllo sovrapposizione processi
echo
echo "--Informazioni sul processo in esecuzione"
LOCKFILE="$TMP_DIR/`basename $0 .sh`.pid" && echo "file di LOCK: $LOCKFILE"
if [ -e $LOCKFILE ] && kill -0 `cat $LOCKFILE`
then
        echo "`basename $0` già in esecuzione: uscita dallo script."
        exit
fi

trap "echo; 
rm -fv $LOCKFILE;
rm -fv $TMP_DIR/*;
rm -v $RADARDIR_CUM/cumulata_oraria.dat;
rm -v $SCARICO_DIR/*.$data*.tiff;
rm -v $RADARDIR_CUM/info.txt;
rm -v $RADARDIR_CUM/listaUIL.txt
rm -v $RADARDIR_CUM/*.gri; 
rm -v $RADARDIR_CUM/*.grd;
echo;
echo \"******* Fine script  `date` *****************\";
exit" INT TERM EXIT

echo $$ > $LOCKFILE && echo "PID di questo processo: `cat $LOCKFILE`"
###	fine controllo

echo

if [ $1 ]
then
	echo "Passata data da riga di comando"
	data=$1
	echo "data del file in esame---------> $data"
	ora=${data:8:2}
	echo "ora del file in esame---------> $ora"
	giorno=${data:6:2}
	echo "giorno del file in esame---------> $giorno"
	mese1=${data:4:2}
	echo "mese del file in esame---------> $mese1"
	anno1=${data:0:4}
	echo "anno del file in esame---------> $anno1"
	mese=`date --date $anno1$mese1$giorno +%b` && echo $mese
	anno=`date --date $anno1$mese1$giorno +%y` && echo $anno
else
	echo "Data ricavata da orologio di sistema"
	data=$(date -d '1 hour ago' +%Y%m%d%H)
	echo "data del file in esame---------> $data"
	ora=$(date -d '1 hour ago' +%H)
	echo "ora del file in esame---------> $ora"
	giorno=$(date -d '1 hour ago' +%d)
	echo "giorno del file in esame---------> $giorno"
	mese=$(date -d '1 hour ago' +%b)
	mese1=$(date -d '1 hour ago' +%m)
	echo "mese del file in esame---------> $mese1"
	anno=$(date -d '1 hour ago' +%y)
	anno1=$(date -d '1 hour ago' +%Y)
	echo "anno del file in esame---------> $anno1"
fi

fls=lista.txt
nomefile_cumulata="cumulata_oraria_"$data".dat"

echo "--ftp sul sito ftp arpa $host per scaricare i dati"
ncftpls ftp://${usr}:${pwr}@${host}/Prisma/meteoswiss.radar.precip.$data* > $TMP_DIR/$fls
echo "codice di uscita di ncftpls: $?"
echo

if [ ! -s "$TMP_DIR/$fls" ]
then
	rm $TMP_DIR/$fls
#	echo -e "--Non ci sono dati su FTP server; li cerco su $SERVER\n"
        echo -e "--Non ci sono dati su FTP server; li cerco su $SERVER1\n"

#	ssh $SERVER "ls -1 /dati/radar/$anno1$mese1/meteoswiss.radar.precip.$data*" > $TMP_DIR/$fls
        ssh $SERVER1 "ls -1 /dati/radar/$anno1$mese1/meteoswiss.radar.precip.$data*" > $TMP_DIR/$fls

	if [ ! -s "$TMP_DIR/$fls" ]
	then
		echo "--Non ci sono dati da scaricare su $SERVER1: esco dal programma"
		exit
	else
		echo -e "--Presenti questi files da scaricare da $SERVER1:\n`cat $TMP_DIR/$fls`"
		cd $SCARICO_DIR
#		scp $SERVER:/dati/radar/$anno1$mese1/"meteoswiss.radar.precip."$data"*" .
                scp $SERVER1:/dati/radar/$anno1$mese1/"meteoswiss.radar.precip."$data"*" .
	fi
else
  echo -e "--Presenti questi files da scaricare da $host:\n`cat $TMP_DIR/$fls`"
	for nomefile in `cat $TMP_DIR/$fls`
	do
	  annomese_dir=`echo $nomefile|awk '{print substr($0,25,6)}'` && echo $annomese_dir
  	cd $SCARICO_DIR
  	ncftpget $node $SCARICO_DIR Prisma/$nomefile
	done
fi

###	inizio elaborazioni
echo

find $SCARICO_DIR -name "*.$data*.tiff" | sort > $TMP_DIR/lista_radar.txt && echo -e "--Lista files scaricati:\n`cat $TMP_DIR/lista_radar.txt`\n"

echo "--Converto in coordinate UTM con script R"

Rscript --save --verbose $BASE/converti_utm.r $TMP_DIR/lista_radar.txt $RADARDIR_CUM

cd $RADARDIR_CUM

echo "--Calcolo la cumulata ORARIA in coordinate UTM con programma cumula_ora"

find . -name "meteoswiss.radar.precip.*.gri" | sort > listaUIL.txt

### lancio programma per cumulare
$BASE/cumula_ora
if [ $? == "0" ]
then
	echo
	echo -e "--Terminato programma cumula_ora senza errori\n"
else
	echo -e "--Terminato programma cumula_ora CON ERRORI!"
fi

echo "--Rinomino file prodotto dal programma cumula_ora"
cp -v cumulata_oraria.dat $RADARDIR_CUM/$nomefile_cumulata #&& cp -v $RADARDIR_CUM/$nomefile_cumulata $GRADS

echo "--Copio su $SERVER1 per PRISMA"
MAX_RETRIES=10
i=0
RC=1

# scp $RADARDIR_CUM/$nomefile_cumulata $SERVER1:/home/meteo/programmi/radar/prisma_ora/dati

source /prisma/s3put.sh
putS3 $RADARDIR_CUM $nomefile_cumulata prova test

# marta: inserisco chiamata syslogger
##if [[ "$?" != "0" ]]; then
##  logger -i -s -p user.err "prisma.sh@libertario: fallita copia bf radar su mediano" -t "PREVISORE"
##  logger -i -s -p user.err "prisma.sh@libertario: fallita copia bf radar su mediano" -t "DATI"
##else
##  echo "copiato bf radar su mediano alle "`date +%Y%m%d%H%M`
##  logger -i -s -p user.notice "prisma.sh@libertario terminato con successo" -t "PREVISORE"
##  logger -i -s -p user.notice "prisma.sh@libertario terminato con successo" -t "DATI"
##fi

exit


