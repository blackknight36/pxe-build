#!/usr/bin/perl

open(INPUT, "<", "input.txt");

my @lines = <INPUT>;

#open(OUTPUT, ">", "/tmp/parted_commands.sh") or die $!;

my $disk = "/dev/sda";
print "parted -s $disk 'mklabel gpt'\n";
	
my $i = 1;
foreach $line (@lines) {
	my @values = split(/\s/, $line);
	if ( $values[3] =~ ".*swap*" ) {
		print "parted -s $disk 'mkpart linux-swap $values[1] $values[2]'\n";
		print "mkswap /dev/$values[0]\n";	
	} else {
		print "parted -s $disk 'mkpart $values[4] $values[1] $values[2]'\n";
		print "mkfs.$values[3] /dev/$values[0]\n";
	}
	$i++;
}

my $numparts = $i -1;

my $mcount = 0;

print "mkdir /mnt/gentoo\n";

foreach $line (@lines) {
	@values = split(/\s/, $line);
	if ( $values[4] eq "/" ) {
		print "mount -t $values[3] /dev/$values[0] /mnt/gentoo\n";
		$mcount++;
	} 
}
	

# now mount the rest
while ($mcount < $numparts) {
	foreach $line (@lines) {
		@values = split(/\s/, $line);
		if ( $values[4] ne "/" ) {
			if ( $values[3] =~ ".*swap*" ) {
				print "swapon /dev/$values[0]\n";
			} else {
				print "mkdir -p /mnt/gentoo$values[4]\n";
				print "mount -t $values[3] /dev/$values[0] /mnt/gentoo$values[4]\n";
			}
		}
			$mcount++;
	}
}

