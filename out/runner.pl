#!/usr/bin/perl
use strict;
$_ = $ARGV[0];
exec("plv8x -d chars -r $_ > $_.sql");
