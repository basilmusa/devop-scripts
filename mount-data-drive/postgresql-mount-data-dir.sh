#!/bin/bash
# THIS DEPENDS ON THE PREVIOUS SCRIPT AND BOTH COULD BE MERGED
set -eux

# This script assumes
# 1. A directory is mounted on a new location called NEW_DATA_DIR
# 2. CURRENT_DATA_DIR holds the current PostgreSQL 
NEW_DATA_DIR=$1
POSTGRES_DATA_DIR=/var/lib/postgresql/9.5/main

# Check NEW_DATA_DIR does not end with "/" character, if so trim it
# Check NEW_DATA_DIR is a directory
# Check NEW_DATA_DIR is already mounted in /etc/fstab
# Check NEW_DATA_DIR is not the same as POSTGRES_DATA_DIR

# First time do this without shutting down postgresql
rsync -aHAX ${NEW_DATA_DIR}/* ${POSTGRES_DATA_DIR}

systemctl stop postgresql

rsync -aHAX ${NEW_DATA_DIR}/* ${POSTGRES_DATA_DIR}
chown -R postgres:postgres ${NEW_DATA_DIR}

systemctl start postgresql
