#!/usr/bin/perl

use Digest::MD5 qw(md5 md5_hex md5_base64);

if ( @ARGV < 4 ) {
	print "usage: build_centos_ramdisk.pl <template_url> <partition_info_file.txt> <pxe_boot_label> <pxe_menulabel>\n";
        exit 1;
}

my $tempname = md5_hex(time());

system("cp /tftpboot/g4l/ramdisk-master /tftpboot/g4l/$tempname");
system("mount -o loop -t ext2 /tftpboot/g4l/$tempname /mnt/temp");

my $templateurl = $ARGV[0];
my $disk = "sda";
my $grubdisk = "hd0";

my $pfile = $ARGV[1];
my $label = $ARGV[2];
my $menulabel = $ARGV[3];

open(INPUT, "<", $pfile);

my @lines = <INPUT>;

open(OUT, ">", "/mnt/temp/parted_commands.sh");

print OUT "parted -s /dev/$disk 'mklabel msdos'\n";
	
my $i = 1;
foreach my $line (@lines) {
	my ($part, $type, $start, $end, $fstype, $label) = split(/\s/, $line);
	if ( $fstype eq "swap" ) {
		print OUT "parted -s /dev/$disk 'mkpart $type $start $end'\n";
		print OUT "mkswap /dev/$part\n";	
	}
	if ( $type eq "extended" ) {
		print OUT "parted -s /dev/$disk 'mkpart $type $start $end'\n";
	}
	else {
		print OUT "parted -s /dev/$disk 'mkpart $type $fstype $start $end'\n";
		print OUT "mkfs -t $fstype -L $label /dev/$part\n";
	}
	$i++;
}

my $numparts = $i -1;

my $mcount = 0;

print OUT "\n";
print OUT "#mount the partitions\n";
print OUT "mkdir /mnt/gentoo\n";

# sort by mount point
@lines = `sort +5 -6 $pfile | grep -v 'swap' | grep -v 'extended' `;

# now mount the partitions
foreach my $line (@lines) {
	my ($part, $type, $start, $end, $fstype, $label) = split(/\s/, $line);
	if ( $label eq "/" ) {
		print OUT "mount -t $fstype /dev/$part /mnt/gentoo\n";
		print OUT "mkdir -p /mnt/gentoo/{boot,home,tmp,usr,var}\n\n";
		$mcount++;
	} else {
		print OUT "mount -t $fstype /dev/$part /mnt/gentoo$label\n";
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

wget -q -O - $templateurl | gunzip | tar -C /mnt/gentoo -xpv 

if [ \$? != 0 ]; then
	echo 'Error downloading template.  Exiting.'
	exit 1
fi

echo 'template installed.  Installing boot loader.'

/mnt/gentoo/sbin/grub --no-floppy --batch << EOF
root ($grubdisk,0)
setup ($grubdisk)
EOF

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
KERNEL /g4l/bz3x0.3
APPEND initrd=/g4l/$tempname.lzma ramdisk_size=65536 root=/dev/ram0

";
close(OUT);

