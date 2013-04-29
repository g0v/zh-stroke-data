#!/usr/bin/env perl
use utf8;
use 5.12.0;
use Encode qw(from_to decode encode);

binmode STDOUT, ":utf8";

mkdir "utf8" unless -e "utf8";

my @files = glob "data/*.xml";
for my $file ( @files ) {
    if ( my ($code) = ($file =~ /(\w+)\.xml/) ) {
        my $a = pack "H4", $code;
        my $word = decode('big5',$a);
        my $utf8 = sprintf "%x",(unpack "U", $word);
        print $utf8, " <= ", $word,"($code)", "\n";
        symlink "../$file" , "utf8/$utf8.xml";
    }
}
