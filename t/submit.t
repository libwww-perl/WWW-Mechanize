use warnings;
use strict;
use lib 't/lib';
use Test::More tests => 13;
use Test::HTTP::LocalServer;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $server = Test::HTTP::LocalServer->spawn;
isa_ok( $server, 'Test::HTTP::LocalServer' );

my $t = WWW::Mechanize->new();
isa_ok( $t, 'WWW::Mechanize', 'Created the object' ) or die;

my $response = $t->get( $server->url );
isa_ok( $response, 'HTTP::Response', 'Got back a response' ) or die;
is( $t->uri, $server->url, "Got the correct page" );
is( ref $t->uri, "", "URI shouldn't be an object" );
ok( $response->is_success, 'Got local page' ) or die "Can't even fetch local page";
ok( $t->is_html );

$t->field(query => "foo"); # Filled the "q" field

$response = $t->submit;
isa_ok( $response, 'HTTP::Response', 'Got back a response' );
ok( $response->is_success, "Can click 'submit' ('submit' button)");
is( ref $t->uri, "", "URI shouldn't be an object" );

like($t->content, qr/\bfoo\b/i, "Found 'Foo'");

SKIP: {
    eval "use Test::Memory::Cycle";
    skip "Test::Memory::Cycle not installed", 1 if $@;

    memory_cycle_ok( $t, "Mech: no cycles" );
}
