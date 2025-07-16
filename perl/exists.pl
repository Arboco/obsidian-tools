#!/usr/bin/perl
use strict;
use warnings;

# Usage: perl get_cardstring.pl "start string" "end string" file1.txt [file2.txt ...]

my $start_string = shift @ARGV;
my $end_string   = shift @ARGV;
my @files        = @ARGV;

foreach my $file (@files) {
    next unless -f $file;

    open my $fh, '<', $file or warn "Can't open $file: $!" and next;
    my @lines = <$fh>;
    close $fh;

    chomp @lines;

    my $collecting = 0;
    my $end_found  = 0;
    my @block      = ();

    foreach my $line (@lines) {
        if (!$collecting) {
            if ($line =~ /\Q$start_string\E/) {
                $collecting = 1;
                push @block, $line;
            }
            next;
        } else {
            last if $line =~ /^\s*$/;  # Stop if empty line (before finding end_string)

            push @block, $line;

            if ($line =~ /\Q$end_string\E/) {
                $end_found = 1;
                last;
            }
        }
    }

    if ($end_found) {
        print "$_\n" for @block;
    }
}
