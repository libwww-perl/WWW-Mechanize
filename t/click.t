use warnings;
use strict;
use lib 't/lib';
use Test::HTTP::LocalServer;
use Test::More tests => 10;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new();
isa_ok( $mech, 'WWW::Mechanize', 'Created the object' );

my $server = Test::HTTP::LocalServer->spawn();
isa_ok( $server, 'Test::HTTP::LocalServer' );

my $response = $mech->get( $server->url );
isa_ok( $response, 'HTTP::Response', 'Got back a response' );
ok( $response->is_success, 'Got URL' ) or die "Can't even fetch local url";
ok( $mech->is_html, "Local page is HTML" );
my @forms = $mech->forms;
is( scalar @forms, 1, "Only one form" );

$mech->field(query => "foo"); # Filled the "q" field

$response = $mech->click("submit");
isa_ok( $response, 'HTTP::Response', 'Got back a response' );
ok( $response->is_success, "Can click 'Go' ('Google Search' button)");

is( $mech->field('query'),"foo", "Filled field correctly");

