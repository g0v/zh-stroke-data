# Usage:
#   createdb strokes
#   perl hausdorff_distance.pl | psql strokes
#   cd sql; ls | xargs -P 8 -n 1 -- psql strokes -f
#
# Adjust "-P 8" above for concurrent CPU cores.
# Tested on PostgreSQL 9.3 using http://postgresapp.com/.
use 5.12.0;
use File::Slurp;
use JSON::XS;
binmode STDOUT, ':utf8';
say 'CREATE EXTENSION IF NOT EXISTS postgis;';
say 'CREATE TABLE IF NOT EXISTS strokes ( ch text NOT NULL, track geometry );';
say 'CREATE TABLE IF NOT EXISTS distance ( ch1 text NOT NULL, ch2 text NOT NULL, distance int );';
say 'DELETE FROM strokes; DELETE FROM distance;';
say 'BEGIN;';
my @chars;
for (<json/*.json>) {
    my $char = $_;
    $char =~ s/^json.|.json$//g;
    $char = chr hex $char;
    my @mls;
    for my $part (@{ JSON::XS::decode_json(File::Slurp::read_file($_)) }) {
        push @mls, [ map { "$_->{x} $_->{y}" } @{  $part->{track} } ];
    }
    say "INSERT INTO strokes VALUES ('$char', ST_GeomFromText('MULTILINESTRING(@{[ join ', ', map { qq[($_)] } map { join ', ', @$_ } @mls ]})'));";
    push @chars, $char;
}
say 'COMMIT;';
mkdir 'sql';
for (@chars) {
    open FH, ">sql/".ord($_).".sql";
    binmode FH, ':utf8';
    print FH qq[
    INSERT INTO distance (
        SELECT '$_' ch1, ch ch2, 
        ST_HausdorffDistance(
            (SELECT track FROM strokes WHERE ch = '$_'), track
        )::int distance FROM strokes where ST_HausdorffDistance(
            (SELECT track FROM strokes WHERE ch = '$_'), track
        )::int BETWEEN 1 AND 199
    );
];
};
