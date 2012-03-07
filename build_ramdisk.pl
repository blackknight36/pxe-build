#!/usr/bin/perl

use Digest::MD5 qw(md5 md5_hex md5_base64);

if ( @ARGV < 5 ) {
	print "usage: build-ramdisk.pl <template_url> <sda|sdb> <partition_info_file.txt> <pxe_boot_label> <pxe_menulabel>\n";
        exit 1;
}

my $tempname = md5_hex(time());

system("cp /tftpboot/g4l/ramdisk-master /tftpboot/g4l/$tempname");
system("mount -o loop -t ext2 /tftpboot/g4l/$tempname /mnt/temp");

my $templateurl = $ARGV[0];
my $disk = $ARGV[1];
my $parteddisk = "$disk";
my $grubdisk = "hd0";

if ( $disk eq "vda" ) {
	$parteddisk = "sda";
} 
	
if ( $disk eq "sdb" ) {
	my $grubdisk = "hd1";
} 

my $label = $ARGV[3];
my $menulabel = $ARGV[4];

open(INPUT, "<", $ARGV[2]);

my @lines = <INPUT>;

open(OUT, ">", "/mnt/temp/parted_commands.sh");

print OUT "parted -s /dev/$parteddisk 'mklabel gpt'\n";
	
my $i = 1;
foreach my $line (@lines) {
	my ($part, $start, $end, $fstype, $label) = split(/\s/, $line);
	if ( $fstype =~ ".*swap*" ) {
		print OUT "parted -s /dev/$parteddisk 'mkpart linux-swap $start $end'\n";
		print OUT "mkswap /dev/$parteddisk$part\n";	
	} else {
		print OUT "parted -s /dev/$parteddisk 'mkpart $label $start $end'\n";
		print OUT "mkfs -t $fstype -L $label /dev/$parteddisk$part\n";
	}
	$i++;
}

my $numparts = $i -1;

my $mcount = 0;

print OUT "\n";
print OUT "mkdir /mnt/gentoo\n";

# sort by mount point
@lines = `sort +4 -5 $ARGV[2] | grep -v 'swap'`;

# now mount the partitions
foreach my $line (@lines) {
	my ($part, $start, $end, $fstype, $label) = split(/\s/, $line);
	if ( $label eq "/" ) {
		print OUT "mount -t $fstype /dev/$parteddisk$part /mnt/gentoo\n";
		$mcount++;
	} else {
		print OUT "mkdir -p /mnt/gentoo$label\n";
		print OUT "mount -t $fstype /dev/$parteddisk$part /mnt/gentoo$label\n";
		$mcount++;
	}
}

# turn on swap
print OUT "swapon -a\n";
close(OUT);

open(OUT, ">", "/mnt/temp/setup.sh");
# create build script
print OUT 
"#!/bin/bash

echo 'partitioning the drive.'

sh /parted_commands.sh

echo 'disk preparation done.  Installing template.'

# changed to use wget
wget -q -O - $templateurl | bunzip2 | tar -C /mnt/gentoo -xpv 

if [ \$? != 0 ]; then
	echo 'Error downloading template.  Exiting.'
	exit 1
fi

echo 'template installed.  Installing boot loader.'

/mnt/gentoo/sbin/grub --no-floppy --batch << EOF
root ($grubdisk,0)
setup ($grubdisk)
EOF

#fix fstab and grub.conf
sed -i -e 's/sda/$disk/' /mnt/gentoo/boot/grub/menu.lst
sed -i -e 's/sda/$disk/' /mnt/gentoo/etc/fstab

echo 'system build done.  Please reboot.'
";

close(OUT);

system("umount /mnt/temp");

print "compressing ramdisk image...\n";
system("lzma -z /tftpboot/g4l/$tempname");

print "/tftpboot/g4l/$tempname.lzma ramdisk created.\n";

open(OUT, ">>", "/tftpboot/pxelinux.cfg/default");

# add pxe entry
print OUT "label $label
MENU LABEL $menulabel
KERNEL g4l/bz3x0.3
APPEND initrd=g4l/$tempname.lzma ramdisk_size=65536 root=/dev/ram0

";
close(OUT);

