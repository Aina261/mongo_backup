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

# Function for create script
function do_backup_script {
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

  # Check if all variable is defined
  if [ -z "$_HOST" ] || [ -z "$_PORT" ] || [ -z "$_DB_NAME" ] || [ -z "$_USERNAME" ] || [ -z "$_PASSWORD" ] || [ -z "$_RETENTION_DAY" ] || [ -z "$_CRON_HOUR" ]; then
    echo -e "\e[91mMmmh, some variables seems to be not configured,\e[0m"
    echo -e "\e[91mYou must answer to all requests,\e[0m"
    echo -e "\e[91mOtherwise the backup will not work\e[0m"
    exit
  fi

  # Mkdir folder
  mkdir -p /etc/mongodb_backup

  # Write file with data
  cat > /etc/mongodb_backup/mongodb_backup_$_DB_NAME.sh <<- EOM
#!/bin/bash

DATE=\$(date +%d-%m-%Y_%H-%M-%S)

echo ""
echo -e "\e[32mStart dump MongoDB database : \$DATE \e[0m"
mongodump --host $_HOST --port $_PORT -u $_USERNAME -p $_PASSWORD --authenticationDatabase $_DB_NAME -o "${_OUTPUT_FOLDER}dump"
echo "Tar dump folder"
tar -czf "${_OUTPUT_FOLDER}mongodump_${_DB_NAME}_"\$DATE".tar.gz" ${_OUTPUT_FOLDER}dump
echo "Remove dump folder"
rm -rf ${_OUTPUT_FOLDER}dump
echo -e "\e[32mEnd dump MongoDB database : \$DATE \e[0m"

echo "Find older backup"
find $_OUTPUT_FOLDER -mindepth 1 -mtime +$_RETENTION_DAY -name '*.tar.gz' -ls
echo "Remove backup older than ${_RETENTION_DAY} days"
find $_OUTPUT_FOLDER -mindepth 1 -mtime +$_RETENTION_DAY -name '*.tar.gz' -delete
echo "Backup successfully remove"
EOM

  # Change mod to executable
  chmod +x /etc/mongodb_backup/mongodb_backup_$_DB_NAME.sh

  cat > /etc/cron.d/mongodb_backup_$_DB_NAME <<- EOM
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 $_CRON_HOUR * * * root /etc/mongodb_backup/mongodb_backup_$_DB_NAME.sh >> /var/log/mongodb_backup.log 2>&1
EOM

  echo -e "\e[32mMongodb_backup file was successfully generated /etc/mongodb_backup/mongodb_backup_${_DB_NAME}.sh\e[0m"
  echo -e "\e[32mCron was successfully added : /etc/cron.d/mongodb_backup_${_DB_NAME}\e[0m"
}

# Ask for how many db to backup
read -rep "How many MongoDB database do you want to backup : " _NUMBER_OF_DB_TO_BACKUP
# Ask for output folder
read -rep "Enter the absolute path of your output archive of your mongodb backup : " _OUTPUT_FOLDER
if ! [ "${_OUTPUT_FOLDER: -1}" = "/" ]; then
    _OUTPUT_FOLDER=$_OUTPUT_FOLDER/
fi

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
  echo -e "\e[32mOutput folder already exist\e[0m"
fi

# Loop on the number of db to backup
for ((i=0; i<$_NUMBER_OF_DB_TO_BACKUP; i++));
do
  echo ""
  echo "Please answer all questions"
  do_backup_script
done

echo ""
echo "Thanks using MongoDB backup"
echo "Logs was here '/var/log/mongodb_backup.log'"
