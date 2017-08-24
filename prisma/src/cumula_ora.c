#include <stdio.h>
#include <string.h>

//program cumula_ora.c        Umberto Pellegrini

//programma per cumulare i dati di precipitazione del radar del Monte Lema.
//Legge i files ogni 5 minuti, decluttera e li somma dando la precipitazione oraria in formato matrice GRADS.
//Modificato per leggere i files del monte lema senza informazioni di orografia e quanto altro...
//17 giugno 2009

//UP 07022012

//Azioni decluttering: 
// 1) su ogni mappa di 5 minuti, con algoritmo tradizionale
// 2) su ogni mappa di 5 minuti utilizzando anche algoritmo per individuare differenze nei valori
// 3) su cumulata oraria con algoritmo tradizionale

int main()
{
char nom[43];
float fval;
int val,i=0,j=0,k=0,m,n;
float dati[160000];
int istart, jstart, iend, jend, np_elim, np_clutter,ls, le, ms, me, nc, ncc, l;
float matrice_dati[400][400];
float matrice_cumulata[400][400];
FILE *in;
FILE *out;
FILE *para;
FILE *info;
info = fopen ("info.txt","w");
out = fopen ("cumulata_oraria.dat","wb");
para = fopen ("listaUIL.txt","r");

//	lettura dei nomi dei files dal file elenco.txt da aprire...
while (fscanf(para,"%s",&nom)!=EOF)
{
	i=0;
	k = k + 1;
	printf ("%d\n",k);
	in = fopen (nom,"rb");
	printf("apro il file %s numero %d\n",nom,k);
	fprintf(info,"Nome file esaminato: %s  Numero file: %d\n",nom,k);
	
//	lettura dati contenuti nel file...
	while ((fread((void*)(&fval), sizeof(fval), 1, in)))
	{
		dati[i]=fval;
//              printf("%f   %d %d\n",fval,i,sizeof(fval));
		i++;
	}
	fclose(in);

//	carico la matrice del radar da declutterare
	m=0;
	n=0;
	i=0;
	for (m=0;m<400;m++)
	{
		for(n=0;n<400;n++)
		{
			matrice_dati[m][n]=dati[i];
			i++;
		}
	}
//	ripulisco i bordi della matrice
	m=0;
	for (m=0; m<400; m++)
	{
		matrice_dati[m][0]=0.;
		matrice_dati[m][399]=0.;
	}
	n=0;
	for (n=0; n<400; n++)
	{
		matrice_dati[0][n]=0.;
		matrice_dati[399][n]=0.;
	}

//	declutter tradizionale su singola mappa 5 minuti 
	istart=1;
	jstart=1;
	iend=398;
	jend=398;
	n=0;
	for (n=0; n<16; n++)
	{
		np_elim=0;
		for (i=istart; i<=iend; i++)
		{
			for (j=jstart; j<=jend; j++)
			{
				if (matrice_dati[j][i]>0.)
				{
					ls=i-1;
					le=i+1;
					ms=j-1;
					me=j+1;
					nc=0;
					for (l=ls; l<=le; l++)
					{
						for (m=ms; m<=me; m++)
						{
							if(matrice_dati[m][l]>0.1)
							{							
								nc=nc+1;
							}
        //                					printf("m %d\n",m);
						}
					}
					if(nc<5)
					{
						matrice_dati[j][i]=0.;
						np_elim=np_elim+1;
					}
                                     /*   if((nc>=5) && (matrice_dati[j][i]<=1))
                                                {
                                                matrice_dati[j][i]=0;
                                                np_elim=np_elim+1;
                                                }  */
				}
			}
		}
		printf("punti eliminati con TD al giro %d:  %d\n",n,np_elim);
	}

//	associazione valori originari con dati di precipitazione...
	i=0;
	j=0;
	for (i=0; i<400; i++)
	{
		for (j=0; j<400; j++)
		{
			matrice_cumulata[i][j]= matrice_cumulata[i][j] + matrice_dati[i][j]/12.;
		}
	}

//	azzero matrice e vettore...
	i=0;
	for (i=0; i<160000; i++)
	{
		dati[i]=0.;
	}

//	azzero matrice dati...
	i=0;
	j=0;
	for (i=0; i<400; i++)
	{
		for (j=0; j<400; j++)
		{
			matrice_dati[i][j]=0.;
		}
	}
	
}	//end while
	
printf("Ho generato la somma delle 12 scadenze: ripulisco ancora una volta la matrice oraria\n");

// ripulisco i bordi della matrice

m=0;
for (m=0; m<400; m++)
	{
	matrice_cumulata[m][0]=0.;
	matrice_cumulata[m][399]=0.;
	}
n=0;
for (n=0; n<400; n++)
 {
	matrice_cumulata[0][n]=0.;
	matrice_cumulata[399][n]=0.;
	}

// qui ci piazzo il declutter
istart=1;
jstart=1;
iend=398;
jend=398;
n=0;
for (n=0; n<15; n++)
{
	np_elim=0;
	for (i=istart; i<=iend; i++)
	{
		for (j=jstart; j<=jend; j++)
		{
			if(matrice_cumulata[i][j]>0)
			{
				ls=i-1;
				le=i+1;
				ms=j-1;
				me=j+1;
				nc=0;
				for (l=ls; l<=le; l++)
				{
					for (m=ms; m<=me; m++)
					{
						if(matrice_cumulata[l][m]>0.1)
						{	
							nc=nc+1;
						}
					}
				}
				if(nc<5)
				{
					matrice_cumulata[i][j]=0.;
					np_elim=np_elim+1;
				}
			}
		}
	}
	printf("punti eliminati su matrice cumulata oraria %d\n",np_elim);
}
	
// scrittura matrice di output in binario	
	
i=0;
j=0;
for (i=0; i<400; i++)
{
	for (j=0; j<400; j++)
	{
//		printf("matrice output= %d\n",matrice_dati[i][j]);
		fwrite(&matrice_cumulata[i][j],sizeof(matrice_cumulata[i][j]),1,out);
	}
}
//        fprintf(info,"punti eliminati e clutter tolto = %d -- %d\n",np_elim,np_clutter);

fclose(out);
//        fclose(info);

return 0;
        
}
