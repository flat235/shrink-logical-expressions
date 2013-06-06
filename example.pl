#!/usr/bin/perl

use strict;
use warnings;

use loglist;

my $list = new loglist(undef);
$list->makelist('A & A | B & ( B & ( F | C ) ) & ( C | D ) & E');
print $list->print;
print "\n";
$list->ease;
print $list->print;
print "\n";
