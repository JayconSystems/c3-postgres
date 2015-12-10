FROM postgres:latest
MAINTAINER Shawn Nock <nock@nocko.se>

ENV POSTGRES_USER c3app_live
ENV POSTGRES_PASSWORD apidemo

RUN apt-get -y update &&\
    apt-get -y install postgis &&\
    rm -rf /var/lib/apt/lists/* &&\
    ldconfig

COPY postgresql.conf /tmp/postgresql.conf
COPY c3_schema.sql /docker-entrypoint-initdb.d/1.sql
#COPY c3_demo_data.sql /docker-entrypoint-initdb.d/2.sql
COPY config-swap.sh /docker-entrypoint-initdb.d/3.sh
