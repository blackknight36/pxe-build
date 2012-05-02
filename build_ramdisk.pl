#!/usr/bin/perl

if ( @ARGV < 1 ) {
	print "usage: build_g4l_ramdisk.pl <pxe_boot_label> <pxe_menulabel>\n";
        exit 1;
}

use Digest::MD5 qw(md5 md5_hex md5_base64);

my $tempname = md5_hex(time());
my $label = $ARGV[0];
my $menulabel = $ARGV[1];

system("cp /tftpboot/g4l/ramdisk-master /tftpboot/g4l/$tempname");

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

