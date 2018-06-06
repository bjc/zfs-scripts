#!/usr/bin/env perl

use strict;
use warnings;

use YAML::Tiny;
use Data::Dumper;

my $conffile = 'backup.conf';

my $conf = YAML::Tiny->read($conffile);
my $srcs = $conf->[0]->{sources};
my $dest = $conf->[0]->{dest};

system("zfs list $dest > /dev/null 2>&1") == 0 or
  die "Error: pool '$dest' not found. Is it imported?\n";

foreach my $src (@$srcs) {
  my ($pool, $fs) = split(/\//, $src, 2);
  my ($from, $to) = limits($pool, $dest, $fs);

  unless (defined $from) {
    print "Warning: $dest does not contain $fs. Initialize with:\n" .
      "\tzfs send -R $pool/$to | zfs recv $dest/$fs\n";
    next;
  }

  if ($from eq $to) {
    print "No new snapshots for $pool/$fs.\n";
    next;
  }

  print "Sending to $dest: $pool/$from -> $to\n";
  my $cmd = "zfs send -RI $pool/$from $pool/$to | zfs recv $dest/$fs";
  system($cmd) == 0 or die "Error: couldn't send snapshots with:\n\t$cmd\n."
}

sub limits {
  my ($src, $dst, $fs) = @_;

  my @dstsnaps = snaps("$dst/$fs");
  my @srcsnaps = snaps("$src/$fs");

  ($dstsnaps[$#dstsnaps], $srcsnaps[$#srcsnaps]);
}

sub snaps {
  my $fs = shift;

  map {
    chomp;
    (split /\//, $_, 2)[1];
  } `zfs list -Ht snap -d 1 -o name -s creation $fs`;
}
