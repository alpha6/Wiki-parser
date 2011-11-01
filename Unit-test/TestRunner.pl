#!/usr/bin/perl -w

use strict;

use Test::Unit::Debug qw(debug_pkgs);
use Test::Unit::TestRunner;

# Uncomment and edit to debug individual packages.
#debug_pkgs(qw/Test::Unit::TestCase/);

foreach(@ARGV){
    print STDERR"$_\n";
    my $testrunner = Test::Unit::TestRunner->new();
    $testrunner->start($_);
};
1;
