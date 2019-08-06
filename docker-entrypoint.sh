#!/bin/sh

crond

echo -e "$CRON_SCHEDULE /backup.sh" | crontab -

sleep 3155760000
