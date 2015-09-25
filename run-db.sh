#!/bin/bash

(cd c3api-demo-db
 docker kill demo-db
 docker rm demo-db
 docker build -t demo-db . && \
 docker run -d --name demo-db demo-db
)
