FROM registry.arpa.local/base/r-base_arpa:latest
LABEL "name=registry.arpa.local/processi/prisma"
LABEL version="1.0"
LABEL decription="image for prisma process"
COPY ./prisma /prisma
COPY ./conf /conf
COPY ./conf/id_rsa* /root/.ssh/
COPY ./conf/known_hosts /root/.ssh
RUN gcc /prisma/src/cumula_ora.c -o /prisma/cumula_ora
WORKDIR /prisma
