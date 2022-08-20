#!perl -T

use warnings;
use strict;
use Test::More tests => 5;
use URI::file ();

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( 't/find_frame.html' )->as_string;

$mech->get( $uri );
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

my $x;
$x = $mech->find_link();
isa_ok( $x, 'WWW::Mechanize::Link' );
is( $x->url, 'bastro.html', 'First link sequentially' );
