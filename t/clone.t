#!perl -Tw

use strict;
use Test::More tests => 3;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new();
isa_ok( $mech, 'WWW::Mechanize' );

my $clone = $mech->clone();
isa_ok( $clone, 'WWW::Mechanize' );
