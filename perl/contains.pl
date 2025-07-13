#!/usr/bin/perl
use strict;
use warnings;

# Usage: perl get_cardstring.pl "start string" "search string" file1.txt [file2.txt ...]

my $start_string  = shift @ARGV;
my $search_string = shift @ARGV;
my @files         = @ARGV;

foreach my $file (@files) {
    next unless -f $file;

    open my $fh, '<', $file or warn "Can't open $file: $!" and next;
    my @lines = <$fh>;
    close $fh;

    chomp @lines;

    my $found_start = 0;

    for (my $i = 0; $i < @lines; $i++) {
        my $line = $lines[$i];

        # Wait until we find the start string
        if (!$found_start) {
            if ($line =~ /\Q$start_string\E/) {
                $found_start = 1;
                print "$line\n";
            }
            next;
        }

        # If we're printing after start_string:
        if ($found_start) {
            last if $line =~ /^\s*$/;  # Stop if empty line
            print "$line\n";

            # Stop if this line contains the search_string
            last if $line =~ /\Q$search_string\E/;
        }
    }
}
