#!/bin/bash

#
# Script for running automated backups for Snipe-IT Docker containers and removing old backups
#
# Mean to be used as part of a crontab
#
# Limits its search for backups to clean up to those in the 'BACKUP_DIR' folder, so
# you can create folders in this location to keep any manual backups for historical purposes
#

# Docker container name to backup
CONTAINER="SNIPE-IT"
# Snipe-IT Docker container backup location
BACKUP_DIR="/config/storage/app/backups/"
# Number of backups to keep
MAX_BACKUPS="14"

# Verify a container name is supplied
if [ "$CONTAINER" = "" ]; then
	/bin/echo "No value supplied for 'CONTAINER'. Please run the script followed by the container name. ex. sh script.sh <container_name>"
	exit 1
fi

# First, complete a backup
/bin/echo "Creating database backup for ${CONTAINER} ..."
docker exec "$CONTAINER" /usr/bin/php /app/www/artisan snipeit:backup

# Process existing backups for cleanup
BACKUPS=$(docker exec "$CONTAINER" /usr/bin/find "$BACKUP_DIR" -maxdepth 1 -type f | /usr/bin/sort -r)
BACKUP_NUM=$((${MAX_BACKUPS} + 1))
OLD_BACKUPS=$(echo $BACKUPS | tail -n +${BACKUP_NUM})

# If old backups found, remove them
if [ "$OLD_BACKUPS" != "" ]; then
	echo "Cleaning up old backups ..."
	for f in $OLD_BACKUPS; do
		echo "Removing old backup: ${f} ..."
		docker exec "$CONTAINER" rm $f
	done
else
	echo "No backups to clean. Done."
fi

exit
