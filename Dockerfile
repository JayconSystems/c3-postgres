FROM postgres:latest
MAINTAINER Shawn Nock <nock@nocko.se>

ENV POSTGRES_USER c3app_live
ENV POSTGRES_PASSWORD apidemo

COPY c3_schema.sql /docker-entrypoint-initdb.d/1.sql
COPY c3_demo_data.sql /docker-entrypoint-initdb.d/2.sql

