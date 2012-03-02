#!/usr/bin/perl

use strict;

if ( @ARGV < 1 ) {
	print "usage: build_parted_script2.pl <partition_info.txt>\n";
	exit;
}

my $file = $ARGV[0];
open(INPUT, "<", $file);

my @lines = <INPUT>;

print "#!/bin/bash\n";

my $disk = "/dev/sda";
print "parted -s $disk 'mklabel gpt'\n";
	
my $i = 1;
foreach my $line (@lines) {
	my ($dev, $start, $end, $fstype, $label) = split(/\s/, $line);
	if ( $fstype =~ ".*swap*" ) {
		print "parted -s $disk 'mkpart linux-swap $start $end'\n";
		print "mkswap /dev/$dev\n";	
	} else {
		print "parted -s $disk 'mkpart $label $start $end'\n";
		print "mkfs -t $fstype -L $label /dev/$dev\n";
	}
	$i++;
}

my $numparts = $i -1;

my $mcount = 0;

print "mkdir /mnt/gentoo\n";

# sort by mount point
my $cmd = "sort +4 -5 $file | grep -v 'swap'";
@lines = `$cmd`;

# now mount the partitions
foreach my $line (@lines) {
	my ($dev, $start, $end, $fstype, $label) = split(/\s/, $line);
	if ( $label eq "/" ) {
		print "mount -t $fstype /dev/$dev /mnt/gentoo\n";
		$mcount++;
	} else {
		print "mkdir -p /mnt/gentoo$label\n";
		print "mount -t $fstype /dev/$dev /mnt/gentoo$label\n";
		$mcount++;
	}
}

# turn on swap
print "swapon -a\n";
