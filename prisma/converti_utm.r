###	converti_utm.r
#	conversione da formato geotiff a matrice dati in coordinate UTM
#	gestione manca dato.
#	cremonini (modificato 30/12/2011); UP modificato 07022012

library(fields)
library(raster)

cols=400
rows=400

ndati=12 # numero di dati radar nell'ora

lev<-read.table("/prisma/level_swiss.txt",na.strings="NA")
lev<-lev$V2

args=(commandArgs(TRUE))

print(args)

infile=scan(args[1],"")
otdir=args[2]

for (i in 1:length(infile)) {

	print(paste("Elaboro il raster", infile[i]))

	r<-raster(infile[i])
	projection(r)<-CRS("+proj=somerc +lat_0=+46.95241 +lon_0=+7.439583 +ellps=bessel +x_0=600000. +y_0=200000.  +k_0=1.")

#	Conversione in livelli di pioggia

	newval<-matrix(lev[(as.matrix(r) + 1)],640,710)

	r<-setValues(r,newval)

#	r[r > 8000]<-NA
#	r[r < 0]<-NA

	r[r > 500]<-0
	r[r < 0]<-0

  if (length(r[r>207])>100000) {
    r[]<-0
    }

#	conversione in UTM32

	utmr<-raster(nrows=rows,ncols=cols,xmn=287000,xmx=(287000+cols*1E3),ymn=4899000,ymx=(4899000+rows*1E3),crs=CRS("+proj=utm +zone=32 +ellps=WGS84"))

	utmr<-projectRaster(r,utmr,method="ngb")

	otfile=paste(otdir,"/",substr(infile[i],28,(nchar(infile[i])-5)),sep="")

	print(otfile)

	writeRaster(utmr,otfile,format="raster",overwrite=TRUE, datatype='FLT4S')

}

