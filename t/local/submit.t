use warnings;
use strict;
use lib qw( t/local );
use Test::More tests => 13;
use LocalServer ();

use Test::Memory::Cycle;

BEGIN {
    delete @ENV{qw( IFS CDPATH ENV BASH_ENV )};
    use_ok('WWW::Mechanize');
}

my $server = LocalServer->spawn;
isa_ok( $server, 'LocalServer' );

my $mech = WWW::Mechanize->new();
isa_ok( $mech, 'WWW::Mechanize', 'Created the object' ) or die;

my $response = $mech->get( $server->url );
isa_ok( $response, 'HTTP::Response', 'Got back a response' ) or die;
is( $mech->uri, $server->url, 'Got the correct page' );
ok( $response->is_success, 'Got local page' )
    or die 'cannot even fetch local page';
ok( $mech->is_html, 'is HTML' );

is( $mech->value('upload'), q{}, 'Hopefully no upload happens' );

$mech->field( query => 'foo' );    # Filled the 'q' field

$response = $mech->submit;
isa_ok( $response, 'HTTP::Response', 'Got back a response' );
ok( $response->is_success, 'Can click "submit" ("submit" button)' );

like( $mech->content, qr/\bfoo\b/i, 'Found "Foo"' );

is( $mech->value('upload'), q{}, 'No upload happens' );

memory_cycle_ok( $mech, 'Mech: no cycles' );
