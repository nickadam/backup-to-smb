#!/bin/sh

if [ ! -z "$SMB_PASS_FILE" ]
then
  SMB_PASS="$(cat $SMB_PASS_FILE)"
  export SMB_PASS
fi

if [ -z "$CRON_SCHEDULE" ] ||
  [ -z "$BACKUP_NAME" ] ||
  [ -z "$RETENTION" ] ||
  [ -z "$SMB_SHARE" ] ||
  [ -z "$SMB_USER" ] ||
  [ -z "$SMB_PASS" ]
then
  echo "Environment variables must be set"
  exit 1
fi

crond

echo -e "$CRON_SCHEDULE /backup.sh" | crontab -

sleep 3155760000
