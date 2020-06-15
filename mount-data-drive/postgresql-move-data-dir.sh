#!/bin/bash
# THIS DEPENDS ON THE PREVIOUS SCRIPT AND BOTH COULD BE MERGED
set -eux

if [ $# -ne 2 ]
then
	echo "";
	echo "    Usage: ./${0} <new_postgresql_data_directory> <current_postgres_data_directory>";
	echo;
	echo "    Example: ./${0} /data-postgresql";
	echo;
	echo "";
	exit 1;
fi

# This script assumes
# 1. A directory is mounted on a new location called NEW_DATA_DIR
# 2. CURRENT_DATA_DIR holds the current PostgreSQL 

############################################################################
# NEW_DATA_DIR
NEW_DATA_DIR=$1
# Check NEW_DATA_DIR does not end with "/" character, if so trim it
NEW_DATA_DIR=${NEW_DATA_DIR%/} # Trim last slash if it exists
# Check NEW_DATA_DIR is a directory
if [[ ! -d $NEW_DATA_DIR ]]; then
  echo "ERROR: [$NEW_DATA_DIR] is not a valid directory.";
  exit 1;
fi

# Check NEW_DATA_DIR is already mounted in /etc/fstab
if mount | grep " ${NEW_DATA_DIR} " > /dev/null; then 
  echo "ERROR: [${NEW_DATA_DIR}] is not mounted yet.";
  exit 1;
fi

############################################################################
# POSTGRES_DATA_DIR
POSTGRES_DATA_DIR=${2%/}
# Check POSTGRES_DATA_DIR is a directory
if [[ ! -d $POSTGRES_DATA_DIR ]]; then
  echo "ERROR: [$POSTGRES_DATA_DIR] is not a valid directory.";
  exit 1;
fi

# Extract whatever directory is postgresql is actually using now.
ACTUAL_POSTGRES_DATA_DIR=`more /etc/postgresql/9.5/main/postgresql.conf | grep data_directory | cut -d"'" -f 2`

# Check NEW_DATA_DIR is not the same as POSTGRES_DATA_DIR
if [ "${ACTUAL_POSTGRES_DATA_DIR}" != "${POSTGRES_DATA_DIR}" ]
   echo "ERROR: [${POSTGRES_DATA_DIR}] is not the current working postgresql directory, the current one is [${ACTUAL_POSTGRES_DATA_DIR}].";
   exit 1;
fi

# First time do this without shutting down postgresql
rsync -aHAX ${POSTGRES_DATA_DIR}/* ${NEW_DATA_DIR}

systemctl stop postgresql

rsync -aHAX ${POSTGRES_DATA_DIR}/* ${NEW_DATA_DIR}
chown -R postgres:postgres ${NEW_DATA_DIR}

# Change to the new data directory by replacing configuration value
ESCAPED_FIND=$(echo ${ACTUAL_POSTGRES_DATA_DIR} | sed -e 's/[]\/$*.^[]/\\&/g');
ESCAPED_REPLACE=$(echo ${NEW_DATA_DIR} | sed -e 's/[\/&]/\\&/g');
sed -i "s/$ESCAPED_FIND/$ESCAPED_REPLACE/g" /etc/postgresql/9.5/main/postgresql.conf

systemctl start postgresql
