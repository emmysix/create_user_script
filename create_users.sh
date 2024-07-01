#!/bin/bash

#Password file path
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"


#Directories
mkdir -p /var/secure
touch $LOG_FILE
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE


#Message log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}


#Filename argument 
if [ -z "$1" ]; then
    echo "Usage: $0 <user-file>"
    log "ERROR: No user file provided."
    exit 1
fi


#User file and process
USER_FILE=$1

if [ ! -f $USER_FILE ]; then
    echo "User file not found: $USER_FILE"
    log "ERROR: User file not found - $USER_FILE"
    exit 1
fi

while IFS=';' read -r username groups; do
    username=$(echo $username | xargs) # Remove whitespace
    groups=$(echo $groups | xargs) # Remove whitespace
    user_group=$username

    #Check if user and user group
    if id "$username" &>/dev/null; then
        log "User $username already exists."
        continue
    fi

    useradd -m -g $user_group -G $(echo $groups | tr ',' ' ') $username
    if [ $? -eq 0 ]; then
        log "Created user $username with groups $groups."
    else
        log "ERROR: Failed to create user $username."
        continue
    fi

    #Generate random password
    password=$(openssl rand -base64 12)

    #Set users password
    echo "$username:$password" | chpasswd
    if [ $? -eq 0 ]; then
        log "Set password for user $username."
        echo "$username,$password" >> $PASSWORD_FILE
    else
        log "ERROR: Failed to set password for user $username."
    fi

done < "$USER_FILE"


chmod 600 $LOG_FILE
chmod 600 $PASSWORD_FILE