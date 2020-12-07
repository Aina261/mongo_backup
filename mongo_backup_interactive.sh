#!/bin/bash

# Test if the script is run with sudo
if [ "$EUID" -ne 0 ]
  then echo "Please run the script as root"
  exit
fi

echo -e "\e[32mWelcome to mongodb backup generator\e[0m"
echo "Now, verify if mongodb is installed"
# Check if mongodb is installed
if [ ! -x "$(command -v mongo)" ]; then
    echo -e "\e[91mMongoDB is not installed on your machine\e[0m"
    echo "You need to have MongoDB installed for dump and backup your DB"
    echo "Please, install it before run this script"
    exit
else
  echo -e "\e[32mMongoDB is installed\e[0m"
fi
# Ask for output folder
read -rep "Enter the absolute path of your output archive of your mongodb backup : " _OUTPUT_FOLDER
# Test if output folder exist
if [ ! -d "$_OUTPUT_FOLDER" ]; then
  read -rep "Your output folder path '$_OUTPUT_FOLDER' doesn't exist, do you want to create it ? (y,n) : " _CREATE_FOLDER
  if [ "$_CREATE_FOLDER" = "y" ] || [ "$_CREATE_FOLDER" = "yes" ]; then
    mkdir -p "$_OUTPUT_FOLDER"
    echo -e "\e[32mOutput folder successfully created\e[0m"
  else
    echo -e "\e[38;5;208mThe script can't be run successfully if the output folder doesn't exist\e[0m"
    exit
  fi
else
  echo -e "\e[32mOutput folder exist\e[0m"
fi

_FILENAME=mongodb_backup.sh
# Ask host ip
read -rep "Enter your mongoDB ip address : " _HOST
# Ask mongoDB port
read -rep "Enter your mongoDB port : " _PORT
# Ask database name
read -rep "Enter your mongoDB database name : " _DB_NAME
# Ask mongoDB user name
read -rep "Enter your mongoDB user name : " _USERNAME
# Ask mongoDB password
read -srep "Enter your mongoDB password : " _PASSWORD
echo ""
# Ask for retention day's number
read -rep "How many days do you want to keep the archives : " _RETENTION_DAY
# Ask for the time to activate the cron
echo "Define when the cron should be activated"
read -rep "( '*/1' is for run each hours, '1' is for run at 1am ) : " _CRON_HOUR

# Mkdir folder
mkdir -p /etc/mongodb_backup

# Write file with data
cat > /etc/mongodb_backup/"$_FILENAME" <<- EOM
#!/bin/bash

HOST="$_HOST"
PORT="$_PORT"
USER="$_USERNAME"
DATABASE="$_DB_NAME"
PASSWD="$_PASSWORD"
OUTPUT_FOLDER="$_OUTPUT_FOLDER"
DATE=\$(date +%d-%m-%Y_%H-%M-%S)
BACKUP_NAME=\$DATE.gz

echo "Start dump MongoDB database : $DATE"
mongodump --host "\$HOST" --port "\$PORT" -u "\$USER" -p "\$PASSWD" --authenticationDatabase "\$DATABASE" -o "\$OUTPUT_FOLDER"
echo "Tar dump folder"
tar -czvf \$BACKUP_NAME \$OUTPUT_FOLDER/dump
echo "Remove dump folder"
rm -rf \$OUTPUT_FOLDER/dump
echo "End dump MongoDB database : $DATE"
find \$OUTPUT_FOLDER -mindepth 1 -mtime +$_RETENTION_DAY -delete
EOM

# Change mod to executable
chmod +x /etc/mongodb_backup/

cat > /etc/cron.d/mongodb_backup <<- EOM
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 $_CRON_HOUR * * *   /etc/mongodb_backup/$_FILENAME > /var/log/mongodb_backup.log 2>&1
EOM

echo -e "\e[32mMongodb_backup file was successfully generated /etc/mongodb_backup/$_FILENAME\e[0m"
echo -e "\e[32mCron was successfully added : /etc/cron.d/mongodb_backup\e[0m"
