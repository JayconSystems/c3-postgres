#!/bin/bash

name=c3db

sh -c "while /bin/true; do inotifywait -e modify -r .; docker stop $name; done" &

while /bin/true; do
    docker kill $name
    docker rm $name
    docker build -t $name .
    docker run -it --name $name -p 5432:5432 $name
    sleep 2
done
