#!/bin/sh

if [ ! -z "$SMB_PASS_FILE" ]
then
  SMB_PASS="$(cat $SMB_PASS_FILE)"
  export SMB_PASS
fi

if [ -z "$CRON_SCHEDULE" ] ||
  [ -z "$BACKUP_NAME" ] ||
  [ -z "$RETENTION" ] ||
  [ -z "$TARGZ" ] ||
  [ -z "$SMB_SHARE" ] ||
  [ -z "$SMB_DOMAIN" ] ||
  [ -z "$SMB_USER" ] ||
  [ -z "$SMB_PASS" ]
then
  echo "Environment variables must be set"
  exit 1
fi

echo "username = $SMB_USER" > /authfile
echo "password = $SMB_PASS" >> /authfile
echo "domain = $SMB_DOMAIN" >> /authfile

crond

echo -e "$CRON_SCHEDULE /backup.sh" | crontab -

sleep 3155760000
