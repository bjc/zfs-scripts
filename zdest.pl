#!/usr/bin/env perl

while (<>) {
	my ($fs) = split /\s+/;
	print "Destroying $fs\n";
	system "zfs destroy $fs";
}
