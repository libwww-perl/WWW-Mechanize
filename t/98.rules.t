#!perl -T

use Test::More tests => 3;
use File::Spec;
use strict;

my $file = File::Spec->catfile( qw( lib WWW ), "Mechanize.pm" );
source_file_ok( $file );

$file = File::Spec->catfile( qw( lib WWW Mechanize ), "Link.pm" );
source_file_ok( $file );

$file = File::Spec->catfile( qw( lib WWW Mechanize ), "Examples.pod" );
source_file_ok( $file );

sub source_file_ok {
    my $file = shift;

    open( my $fh, "<", $file ) or die "Can't open $file: $!";
    my @lines = <$fh>;
    close $fh;

    my $n = 0;
    for ( @lines ) {
        ++$n;
        s/^/$file ($n): /;
    }

    my @x = grep /XXX/, @lines;

    if ( !is( scalar @x, 0, "Looking for XXXes" ) ) {
        diag( $_ ) for @x;
    }
}
