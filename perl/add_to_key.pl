#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;

my $search_string = shift @ARGV or die "Usage: $0 <search_string> [search_dir]\n";
my $search_dir = shift @ARGV || '.';

my @results;

find(\&wanted, $search_dir);

sub wanted {
    return unless -f $_;

    my $file = $File::Find::name;
    open my $fh, '<', $file or return;

    my @lines = <$fh>;
    close $fh;

    for (my $i = 0; $i < @lines; $i++) {
        if ($lines[$i] =~ /\Q$search_string\E\s*(\d+)/) {
            my $value = $1;  # Extract number after the search string

            for (my $j = $i - 1; $j >= 0; $j--) {
                if ($lines[$j] =~ /^K:/) {
                    my $k_line = $lines[$j];
                    $k_line =~ s/^\s+|\s+$//g;

                    push @results, "$search_string $value | $k_line";
                    last;
                }
            }
        }
    }
}

print "$_\n" for @results;
