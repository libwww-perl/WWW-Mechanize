use warnings;
use strict;
use Test::More tests => 19;
use lib 't/lib';
use Test::HTTP::LocalServer;
my $server = Test::HTTP::LocalServer->spawn;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize', 'Created object' );
$agent->quiet(1);

$agent->get( $server->url );
ok( $agent->success, 'Got some page' );
is( $agent->uri, $server->url, 'Got local server page' );
is( ref $agent->uri, "", "URI shouldn't be an object" );

ok(! $agent->follow(99999), "Can't follow too-high-numbered link");

ok($agent->follow(1), "Can follow first link");
is( ref $agent->uri, "", "URI shouldn't be an object" );
isnt( $agent->uri, $server->url, 'Need to be on a separate page' );

ok($agent->back(), "Can go back");
is( ref $agent->uri, "", "URI shouldn't be an object" );
is( $agent->uri, $server->url, 'Back at the first page' );

ok(! $agent->follow(qr/asdfghjksdfghj/), "Can't follow unlikely named link");

ok($agent->follow("Link /foo"), "Can follow obvious named link");
is( ref $agent->uri, "", "URI shouldn't be an object" );
isnt( $agent->uri, $server->url, 'Need to be on a separate page' );

ok($agent->back(), "Can still go back");
is( ref $agent->uri, "", "URI shouldn't be an object" );
is( $agent->uri, $server->url, 'Back at the start page again' );
