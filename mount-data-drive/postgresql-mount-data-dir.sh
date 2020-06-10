#!/bin/bash
# THIS DEPENDS ON THE PREVIOUS SCRIPT AND BOTH COULD BE MERGED
set -eux
apt-get update
apt-get install -y postgresql
systemctl stop postgresql
umount /data || /bin/true
mv /var/lib/postgresql /var/lib/postgresql.bak
mkdir -p /var/lib/postgresql
sed  -i 's/ \/data / \/var\/lib\/postgresql /g' /etc/fstab
mount -a
rsync -aHAX /var/lib/postgresql.bak/* /var/lib/postgresql
chown -R postgres:postgres /var/lib/postgresql
rm -rf "/var/lib/postgresql.bak"
rm -rf "/var/lib/postgresql/lost+found"
systemctl start postgresql
