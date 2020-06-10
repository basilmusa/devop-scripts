#!/bin/bash
set -eux

## SAFETY CHECK ###########################################################
# Check if /dev/vdb is mounted, if yes, then exit
if [[ $(/bin/mount | grep -q "/dev/vdb") ]]; then
  echo "BLOCK DEVICE /dev/vdb ALREADY MOUNTED"
  exit 1;
fi

## SAFETY CHECK ###########################################################
if [[ $(/sbin/blkid /dev/vdb) ]]; then
  echo "BLOCK DEVICE ALREADY INITIALIZED, WILL NOT PROCEED WITH SCRIPT";
  exit 1;
fi

## CREATE PARTITION TABLE AND CREATE PARTITION
parted --script /dev/vdb mklabel gpt
parted --script /dev/vdb mkpart primary ext4 0% 100%

## NEEDED FOR lsblk TO REFRESH
echo "Sleeping 5 seconds"
sleep 5;

## PARTITIONNAME WITHOUR '/dev' 
PARTITION_NAME=`lsblk -l /dev/vdb | tail -1 | awk '{print $1}'`

## SAFETY CHECK ###########################################################
if [[ ${#PARTITION_NAME} -ne 4 ]]; then
  echo "EXITING SINCE [$PARTITION_NAME] DOES NOT CONTAIN 4 CHARACTERS";
  exit 1;
fi;

## Format it as ext4
mkfs.ext4 "/dev/$PARTITION_NAME"

## Create a mount directory at /data if does not exist
mkdir -p /data

# Mount it in /etc/fstab
UUID_STRING=`blkid -o export /dev/$PARTITION_NAME | grep "^UUID"`
echo -e "\n$UUID_STRING /data ext4 defaults,nofail 0 0" >> /etc/fstab

# Run mount -a
mount -a

# TO RESET THE BLOCK DEVICE
# umount /dev/vdb1
# wipefs -a /dev/vdb1
# parted /dev/vdb rm 1
# wipefs -a /dev/vdb
