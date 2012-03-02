#!/bin/bash

echo "hello world!"

echo "partitioning the drive."

sh /parted_commands.sh

echo "disk preparation done.  Installing template."

# changed to use wget
wget -q -O - http://192.168.0.1/templates/gentoo/bbs_boot_partition-20110714.tar.bz2 | bunzip2 | tar -C /mnt/gentoo -xpv 
wget -q -O - http://192.168.0.1/templates/gentoo/bbs_root_partition-20110714.tar.bz2 | bunzip2 | tar -C /mnt/gentoo -xpv 
wget -q -O - http://192.168.0.1/templates/gentoo/dev.tar.bz2 | bunzip2 | tar -C /mnt/gentoo -xpv 

echo "template installed.  Installing boot loader."

/mnt/gentoo/sbin/grub --no-floppy --batch << EOF
root (hd0,0)
setup (hd0)
EOF

echo "system build done.  Please reboot."

