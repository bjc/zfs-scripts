#!/usr/bin/env perl

use strict;
use warnings;
use Date::Calc qw(Today_and_Now Delta_YMD Date_to_Time);

# Time machine policy
# hourly for last 24 hours, daily for month, weekly for everything else.

my $FUDGE = 900; # Number of seconds to allow for something to be w/i a day.

my %vols;
my %today;
($today{year}, $today{mon}, $today{day}, $today{hour}, $today{min}, $today{sec}) = Today_and_Now();
my $now = Date_to_Time($today{year}, $today{mon}, $today{day}, $today{hour}, $today{min}, $today{sec});

while (my $line = <>) {
    next unless $line =~ /([^@]+)@(\d{4})-(\d{2})-(\d{2})-(\d{2})(\d{2})(\d{2})/;
    my($volname, $year, $mon, $day, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6, $7);
    my $then = Date_to_Time($year, $mon, $day, $hour, $min, $sec);

    my %volinfo;
    %volinfo = %{$vols{$volname}} if defined($vols{$volname});

    my $shouldkeep = 0;
    my($dy, $dm, $dd) = Delta_YMD($year, $mon, $day, $today{year}, $today{mon}, $today{day});
    $dm += $dy * 12;
    if ($now - $then <= (86400 + $FUDGE)) {
        # Keep everything less than a day old.
        $shouldkeep = 1;
    } elsif ($dm == 0 || ($dm == 1 && $dd >= 0)) {
        # Less than a month old: only keep dailies.
        if (!$volinfo{firstday} || $then - $volinfo{firstday} >= 86400) {
            $volinfo{firstday} = $then;
            $shouldkeep = 1;
        }
    } else {
        # More than a month old: keep weeklies.
        if (!$volinfo{firstweek} || $then - $volinfo{firstweek} >= (86400 * 7 - $FUDGE)) {
            $volinfo{firstweek} = $then;
            $shouldkeep = 1;
        }
    }

    $vols{$volname} = \%volinfo;
    print $line unless $shouldkeep;
}
