#!/bin/bash

name=demo-db

sh -c "while /bin/true; do inotifywait -e modify -r .; docker stop $name; done" &

while /bin/true; do
    docker kill $name
    docker rm $name
    docker build -t $name .
    docker run -it --name $name -p 3306:3306 $name
    sleep 2
done
