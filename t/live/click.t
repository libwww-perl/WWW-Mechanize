#!perl -T

use warnings;
use strict;
use Test::More tests=>8;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new();
isa_ok( $mech, 'WWW::Mechanize' );

my $response = $mech->get( "http://www.google.com/intl/en/");
isa_ok( $response, 'HTTP::Response', 'Got back a response' );
ok( $response->is_success, 'Got google' ) or die "Can't even fetch google";
ok( $mech->is_html );

$mech->field(q => "foo"); # Filled the "q" field

$response = $mech->click("btnG");
isa_ok( $response, 'HTTP::Response', 'Got back a response' );
ok( $response->is_success, "Can click 'btnG' ('Google Search' button)");

like($mech->content, qr/foo\s?fighters/i, "Found 'Foo Fighters'");
