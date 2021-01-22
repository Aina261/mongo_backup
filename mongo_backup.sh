#!/bin/bash

# USAGE
# To get and run this script
# sudo  sh -c "$(curl -fsSl https://raw.githubusercontent.com/Aina261/mongo_backup/main/mongo_backup.sh)"
# You need to run it with sudo
# MongoDB need to be installed on the machine where you run this script

printf "\e[32m"
cat << EOF
                  • ▌ ▄ ·.        ▐ ▄  ▄▄ •       ·▄▄▄▄  ▄▄▄▄·     ▄▄▄▄·  ▄▄▄·  ▄▄· ▄ •▄ ▄• ▄▌ ▄▄▄·
                  ·██ ▐███▪▪     •█▌▐█▐█ ▀ ▪▪     ██▪ ██ ▐█ ▀█▪    ▐█ ▀█▪▐█ ▀█ ▐█ ▌▪█▌▄▌▪█▪██▌▐█ ▄█
  Welcome to      ▐█ ▌▐▌▐█· ▄█▀▄ ▐█▐▐▌▄█ ▀█▄ ▄█▀▄ ▐█· ▐█▌▐█▀▀█▄    ▐█▀▀█▄▄█▀▀█ ██ ▄▄▐▀▀▄·█▌▐█▌ ██▀·     generator
                  ██ ██▌▐█▌▐█▌.▐▌██▐█▌▐█▄▪▐█▐█▌.▐▌██. ██ ██▄▪▐█    ██▄▪▐█▐█ ▪▐▌▐███▌▐█.█▌▐█▄█▌▐█▪·•
                  ▀▀  █▪▀▀▀ ▀█▄▀▪▀▀ █▪·▀▀▀▀  ▀█▄▀▪▀▀▀▀▀• ·▀▀▀▀     ·▀▀▀▀  ▀  ▀ ·▀▀▀ ·▀  ▀ ▀▀▀ .▀
EOF
printf "\e[0m"

printf "Let's verify if the script is run as root"
echo ""
# Test if the script is run with sudo
if ! [ $(id -u) = 0 ]; then
  printf "Please run the script as root"
  exit 1
else
  printf "\e[32mYeah, it's ok\e[0m"
  echo ""
fi

printf "Now, verify if mongodb is installed"
echo ""
# Check if mongodb is installed
if [ ! -x "$(command -v mongo)" ]; then
  printf "\e[91mMongoDB is not installed on your machine\e[0m"
  echo ""
  printf "You need to have MongoDB installed for dump and backup your DB"
  echo ""
  printf "Please, install it before run this script"
  exit 1
else
  printf "\e[32mGreat, mongoDB is installed\e[0m"
  echo ""
fi

# Function for create script
do_backup_script() {
  # Ask host ip
  read -rp "Enter your mongoDB ip address : " _HOST
  # Ask mongoDB port
  read -rp "Enter your mongoDB port : " _PORT
  # Ask database name
  read -rp "Enter your mongoDB database name : " _DB_NAME
  # Ask mongoDB user name
  read -rp "Enter your mongoDB user name : " _USERNAME
  # Ask mongoDB password
  read -rp "Enter your mongoDB password : " _PASSWORD
  # Ask for retention day's number
  read -rp "How many days do you want to keep the archives : " _RETENTION_DAY
  # Ask for the time to activate the cron
  printf "Define when the cron should be activated"
  read -rp "( '*/1' is for run each hours, '1' is for run at 1am ) : " _CRON_HOUR

  # Check if all variable is defined
  if [ -z "$_HOST" ] || [ -z "$_PORT" ] || [ -z "$_DB_NAME" ] || [ -z "$_USERNAME" ] || [ -z "$_PASSWORD" ] || [ -z "$_RETENTION_DAY" ] || [ -z "$_CRON_HOUR" ]; then
    printf "\e[91mMmmh, some variables seems to be not configured,\e[0m"
    printf "\e[91mYou must answer to all requests,\e[0m"
    printf "\e[91mOtherwise the backup will not work\e[0m"
    exit
  fi

  # Mkdir folder
  mkdir -p /etc/mongodb_backup

  # Write file with data
  cat >/etc/mongodb_backup/mongodb_backup_$_DB_NAME.sh <<-EOM
#!/bin/bash

DATE=\$(date +%d-%m-%Y_%H-%M-%S)

echo ""
echo -e "\e[32mStart dump MongoDB database : \$DATE \e[0m"
mongodump --host $_HOST --port $_PORT -u $_USERNAME -p $_PASSWORD --authenticationDatabase $_DB_NAME -o /var/backups/mongodb_backup/dump
echo "Tar dump folder"
tar -czf "/var/backups/mongodb_backup/dump_${_DB_NAME}_"\$DATE".tar.gz" /var/backups/mongodb_backup/dump
echo "Remove dump folder"
rm -rf /var/backups/mongodb_backup/dump
echo -e "\e[32mEnd dump MongoDB database : \$DATE \e[0m"

echo "Find older backup"
find /var/backups/mongodb_backup -mindepth 1 -mtime +$_RETENTION_DAY -name '*.tar.gz' -ls
echo "Remove backup older than ${_RETENTION_DAY} days"
find /var/backups/mongodb_backup -mindepth 1 -mtime +$_RETENTION_DAY -name '*.tar.gz' -delete
echo "Backup successfully remove"
EOM

  # Change mod to executable
  chmod +x /etc/mongodb_backup/mongodb_backup_$_DB_NAME.sh

  cat >/etc/cron.d/mongodb_backup_$_DB_NAME <<-EOM
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 $_CRON_HOUR * * * root /etc/mongodb_backup/mongodb_backup_$_DB_NAME.sh >> /var/log/mongodb_backup.log 2>&1
EOM

  echo ""
  printf "\e[32mThanks using MongoDB backup generator\e[0m"
  echo ""
  printf "Mongodb_backup file was successfully generated /etc/mongodb_backup/mongodb_backup_${_DB_NAME}.sh"
  echo ""
  printf "Cron was successfully added : /etc/cron.d/mongodb_backup_${_DB_NAME}"
  echo ""
  printf "Logs '/var/log/mongodb_backup.log'"
  echo ""
  printf "Backup folder '/var/backups/mongodb_backup'"
}

## Ask for how many db to backup
#printf ""
#read -rp "How many MongoDB database do you want to backup : " _NUMBER_OF_DB_TO_BACKUP

# Test if output folder exist and create it if not
if [ ! -d /var/backups/mongodb_backup ]; then
  mkdir -p /var/backups/mongodb_backup
fi
#
#COUNTER=1
#while [ $COUNTER -le "$_NUMBER_OF_DB_TO_BACKUP" ]; do
#  echo ""
#  printf "** Please answer to all questions **"
#  echo ""
#
#  ((COUNTER++))
#done

do_backup_script
