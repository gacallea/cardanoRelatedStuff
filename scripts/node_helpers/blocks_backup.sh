#!/bin/bash

### https://github.com/gacallea/cardanoRelatedStuff
## this script backups 'blocks.sqlite' every 1h to offer a safety net in case it's needed
## put the script in '/root/blocks_backup.sh'
## put this in root's crontab (crontab -e):
## 0 */1 * * * /root/blocks_backup.sh

JORMUNGANDR_USERNAME="<YOUR_POOL_USER>"
JORMUNGANDR_FILES="/home/${JORMUNGANDR_USERNAME}"
JORMUNGANDR_STORAGE_DIR="${JORMUNGANDR_FILES}/storage"
JORMUNGANDR_STORAGE_FILE="${JORMUNGANDR_STORAGE_DIR}/blocks.sqlite"
JORMUNGANDR_BACKUP_DIR="/root/backups"
JORMUNGANDR_BACKUP_FILE="${JORMUNGANDR_BACKUP_DIR}/blocks.$(date +%F-%H%M%S).sqlite.backup"

if [ ! -d $JORMUNGANDR_BACKUP_DIR ]; then
    mkdir -p $JORMUNGANDR_BACKUP_DIR
fi

cp $JORMUNGANDR_STORAGE_FILE $JORMUNGANDR_BACKUP_FILE
sleep 5
bzip2 $JORMUNGANDR_BACKUP_FILE

## remove backups older than 24h
find $JORMUNGANDR_BACKUP_DIR -type f -mtime +0 -exec rm -f '{}' \;
