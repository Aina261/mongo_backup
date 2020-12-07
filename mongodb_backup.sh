#!/bin/bash

HOST="kjh"
PORT="kljh"
USER="kljoh"
DATABASE="kljh"
PASSWD="kljh"
OUTPUT_FOLDER="lkjh"
DATE=$(date +%d-%m-%Y_%H-%M-%S)
BACKUP_NAME=$DATE.gz

echo "Start dump MongoDB database : "
mongodump --host "$HOST" --port "$PORT" -u "$USER" -p "$PASSWD" --authenticationDatabase "$DATABASE" -o "$OUTPUT_FOLDER"
echo "Tar dump folder"
tar -czvf $BACKUP_NAME $OUTPUT_FOLDER/dump
echo "Remove dump folder"
rm -rf $OUTPUT_FOLDER/dump
echo "End dump MongoDB database : "
