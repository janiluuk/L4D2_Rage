#!/bin/bash

for i in ./*.mp3
do
echo rage-music/$(basename $i) TAG- $(basename $i) >>../../sourcemod/data/music_mapstart.txt
done;


