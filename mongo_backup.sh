#!/bin/bash
echo "\e[32m"
cat << EOF
                  • ▌ ▄ ·.        ▐ ▄  ▄▄ •       ·▄▄▄▄  ▄▄▄▄·     ▄▄▄▄·  ▄▄▄·  ▄▄· ▄ •▄ ▄• ▄▌ ▄▄▄·
                  ·██ ▐███▪▪     •█▌▐█▐█ ▀ ▪▪     ██▪ ██ ▐█ ▀█▪    ▐█ ▀█▪▐█ ▀█ ▐█ ▌▪█▌▄▌▪█▪██▌▐█ ▄█
  Welcome to      ▐█ ▌▐▌▐█· ▄█▀▄ ▐█▐▐▌▄█ ▀█▄ ▄█▀▄ ▐█· ▐█▌▐█▀▀█▄    ▐█▀▀█▄▄█▀▀█ ██ ▄▄▐▀▀▄·█▌▐█▌ ██▀·     generator
                  ██ ██▌▐█▌▐█▌.▐▌██▐█▌▐█▄▪▐█▐█▌.▐▌██. ██ ██▄▪▐█    ██▄▪▐█▐█ ▪▐▌▐███▌▐█.█▌▐█▄█▌▐█▪·•
                  ▀▀  █▪▀▀▀ ▀█▄▀▪▀▀ █▪·▀▀▀▀  ▀█▄▀▪▀▀▀▀▀• ·▀▀▀▀     ·▀▀▀▀  ▀  ▀ ·▀▀▀ ·▀  ▀ ▀▀▀ .▀
EOF
echo "\e[0m"

echo "Let's verify if the script is run as root"
# Test if the script is run with sudo
if ! [ $(id -u) = 0 ]; then
  echo "Please run the script as root"
  exit 1
else
  echo "\e[32mYeah, it's ok\e[0m"
fi

echo "Now, verify if mongodb is installed"
# Check if mongodb is installed
if [ ! -x "$(command -v mongo)" ]; then
  echo "\e[91mMongoDB is not installed on your machine\e[0m"
  echo "You need to have MongoDB installed for dump and backup your DB"
  echo "Please, install it before run this script"
  exit
else
  echo "\e[32mGreat, mongoDB is installed\e[0m"
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
  echo "Define when the cron should be activated"
  read -rp "( '*/1' is for run each hours, '1' is for run at 1am ) : " _CRON_HOUR

  # Check if all variable is defined
  if [ -z "$_HOST" ] || [ -z "$_PORT" ] || [ -z "$_DB_NAME" ] || [ -z "$_USERNAME" ] || [ -z "$_PASSWORD" ] || [ -z "$_RETENTION_DAY" ] || [ -z "$_CRON_HOUR" ]; then
    echo "\e[91mMmmh, some variables seems to be not configured,\e[0m"
    echo "\e[91mYou must answer to all requests,\e[0m"
    echo "\e[91mOtherwise the backup will not work\e[0m"
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

  echo "\e[32mMongodb_backup file was successfully generated /etc/mongodb_backup/mongodb_backup_${_DB_NAME}.sh\e[0m"
  echo "\e[32mCron was successfully added : /etc/cron.d/mongodb_backup_${_DB_NAME}\e[0m"
}

# Ask for how many db to backup
echo ""
read -rp "How many MongoDB database do you want to backup : " _NUMBER_OF_DB_TO_BACKUP

# Test if output folder exist and create it if not
if [ ! -d /var/backups/mongodb_backup ]; then
  mkdir -p /var/backups/mongodb_backup
fi

# Loop on the number of db to backup
#for i in {1..$_NUMBER_OF_DB_TO_BACKUP}; do
#  echo ""
#  echo "Please answer all questions"
#  do_backup_script
#done

COUNTER=1
while [ $COUNTER -le "$_NUMBER_OF_DB_TO_BACKUP" ]; do
  echo ""
  echo "Let's go for DB backup number: $COUNTER"
  echo "** Please answer to all questions **"
  do_backup_script
  ((COUNTER++))
done

echo ""
echo "Thanks using MongoDB backup generator"
echo "You can see backup logs here '/var/log/mongodb_backup.log'"
