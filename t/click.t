use warnings;
use strict;
use Test::More tests => 7;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $t = WWW::Mechanize->new();
isa_ok( $t, 'WWW::Mechanize', 'Created the object' );

my $response = $t->get( "http://www.google.com/intl/en/");
isa_ok( $response, 'HTTP::Response', 'Got back a response' );
ok( $response->is_success, 'Got google' ) or die "Can't even fetch google";

$t->field(q => "foo"); # Filled the "q" field

$response = $t->click("btnG");
isa_ok( $response, 'HTTP::Response', 'Got back a response' );
ok( $response->is_success, "Can click 'btnG' ('Google Search' button)");

like($t->content, qr/foo\s?fighters/i, "Found 'Foo Fighters'");
