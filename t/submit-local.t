use warnings;
use strict;
use Test::More tests => 8;

use lib 't/lib';
use Test::HTTP::LocalServer;
my $server = Test::HTTP::LocalServer->spawn;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $t = WWW::Mechanize->new();
isa_ok( $t, 'WWW::Mechanize', 'Created the object' ) or die;

my $response = $t->get( $server->url );
isa_ok( $response, 'HTTP::Response', 'Got back a response' ) or die;
ok( $response->is_success, 'Got local page' ) or die "Can't even fetch local page";
ok( $t->is_html );

$t->field(query => "foo"); # Filled the "q" field

$response = $t->submit;
isa_ok( $response, 'HTTP::Response', 'Got back a response' );
ok( $response->is_success, "Can click 'submit' ('submit' button)");

like($t->content, qr/\bfoo\b/i, "Found 'Foo'");
