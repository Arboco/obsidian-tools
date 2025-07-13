#!/usr/bin/env perl
use strict;
use warnings;

my $search_string = shift @ARGV;  # First arg: search string
my @files = @ARGV;                # Remaining args: files to search

my @results;

foreach my $file (@files) {
    next unless -f $file;

    open my $fh, '<', $file or warn "Can't open $file: $!" and next;
    my @lines = <$fh>;
    close $fh;

    for (my $i = 0; $i < @lines; $i++) {
        if ($lines[$i] =~ /\Q$search_string\E\s*(.*)/) {
            my $value = $1;  # Extract number or whatever after search string

            # Search backward for lines starting with string 
            for (my $j = $i - 1; $j >= 0; $j--) {
                last if $lines[$j] =~ /^\s*$/;  # Stop if empty line
                if ($lines[$j] =~ /^(Q|W|I|D):/) {
                    my $k_line = $lines[$j];
                    $k_line =~ s/^\s+|\s+$//g;

                    push @results, "$k_line";
                    last;
                }
            }
        }
    }
}

print "$_\n" for @results;
