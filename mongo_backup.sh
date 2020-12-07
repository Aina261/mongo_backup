#!/bin/bash

HOST="sqdgfhdqsh"
PORT="sqdfgh654sdh"
USER="hsdg6fh54sdfg"
DATABASE=admin
PASSWD="sh6dfg54hs"
OUTPUT_FOLDER=/mnt/backup/mongo
DATE=07-12-2020_06-08-43
BACKUP_NAME=.gz

echo "Start dump MongoDB database : "
mongodump --host  --port  -u root -p  --authenticationDatabase  -o /dump
echo "Tar dump folder"
tar -czvf  /dump
echo "Remove dump folder"
rm -rf /dump
echo "End dump MongoDB database : "
