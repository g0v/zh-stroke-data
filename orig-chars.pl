# Usage:
#   createdb chars
#   perl orig-chars.pl | psql chars
use 5.12.0;
use File::Slurp;
use JSON::XS;
binmode STDOUT, ':utf8';
say 'CREATE EXTENSION IF NOT EXISTS postgis;';
say 'CREATE TABLE IF NOT EXISTS strokes ( ch text NOT NULL, outlines geometry[], tracks geometry[] );';
say 'CREATE INDEX idx_ch on strokes (ch);';
say 'DELETE FROM strokes;';
my $orig = File::Slurp::read_file('orig-chars.json', { binmode => ':utf8' });
my @chars;
for my $char (split //, $orig) {
    next if $char eq '"';
    my $file = sprintf("json/%x.json", ord $char);
    my (@mls, @tracks);
    for my $part (@{ JSON::XS::decode_json(File::Slurp::read_file($file)) }) {
        push @mls, [ map {
            $_->{begin} ? (
                "$_->{begin}{x} $_->{begin}{y}",
                ($_->{mid} ? "$_->{mid}{x} $_->{mid}{y}" : ()),
                "$_->{end}{x} $_->{end}{y}",
            ) : "$_->{x} $_->{y}"
        } @{  $part->{outline} } ];
        push @tracks, [ map { "$_->{x} $_->{y}" } @{  $part->{track} } ];
    }
    say "INSERT INTO strokes VALUES ('$char', ARRAY[
        @{[ join ', ', map { qq[ST_GeomFromText('POLYGON(($_))')] } map { join ', ', @$_ } @mls ]}
    ], ARRAY[
        @{[ join ', ', map { qq[ST_GeomFromText('LINESTRING($_)')] } map { join ', ', @$_ } @tracks ]}
    ]);"
}
