#!/bin/bash

yum clean all

/usr/local/cpanel/bin/tailwatchd stop
/etc/init.d/mysql stop

cd /

screen /bin/tar -czvf cpanel-template-lwdefault.tar.gz --exclude=proc/* --exclude=selinux/* --exclude=home/* --exclude=sys/* --exclude=dev/.udev/* --exclude=*/lost+found --exclude=lost+found --exclude=tmp/* --exclude=var/tmp/* --exclude=mnt/* --exclude=etc/ssh/*key* --exclude=cpanel-template*.tar.gz --exclude=root/mk_backup.sh --exclude=root/.bash_history /
