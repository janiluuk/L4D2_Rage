#!/bin/bash

for i in ./*.mp3
do
echo TS_SERVER/$(basename $i) TAG- $(basename $i) >>music_mapstart.txt
done;


