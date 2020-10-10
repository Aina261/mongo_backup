#!/bin/bash

HOST=192.168.1.113
PORT=27017
USER=admin
DATABASE=admin
PASSWD=zqoN602sxsWtc71MF3IFpg08xFS7rUNliJSPsmwVHtN2UP7LLTGAiOjhnTPEOuLdSPFvXJhj1nkmin37i97X7nH9j71IcM4Tju4
OUTPUT_FOLDER=/mnt/backup/mongo
DATE=$(date +%d-%m-%Y_%H-%M-%S)
BACKUP_NAME=$DATE.gz

echo "Start dump MongoDB database : $DATE"
mongodump --host $HOST --port $PORT -u $USER -p $PASSWD --authenticationDatabase $DATABASE -o $OUTPUT_FOLDER/dump
echo "Tar dump folder"
tar -czvf $BACKUP_NAME $OUTPUT_FOLDER/dump
echo "Remove dump folder"
rm -rf $OUTPUT_FOLDER/dump
echo "End dump MongoDB database : $DATE"
