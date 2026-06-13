use warnings;
use strict;

use Test::More;

use lib         qw( t/local );
use LocalServer ();

use Test::Memory::Cycle;

BEGIN {
    delete @ENV{qw( IFS CDPATH ENV BASH_ENV )};
}

use WWW::Mechanize ();

my $server = eval { LocalServer->spawn };
plan skip_all => "Could not start local test server: $@"
    unless $server;

# trailing slash so a relative get('.') resolves back to the same /referer/
# path rather than the server root
my $url = $server->url . 'referer/';

# autocheck off so a failed request fails its own test instead of aborting
# the plan; noproxy and a short timeout so a configured proxy or a dropped
# loopback connection cannot misdirect or stall the test.
my $agent = WWW::Mechanize->new(
    autocheck => 0,
    noproxy   => 1,
    timeout   => 30,
);

# The first request doubles as a reachability check: skip cleanly (rather
# than failing every assertion) in restricted environments that cannot
# actually connect to the local server.
$agent->get($url);
plan skip_all => 'Cannot reach the local test server: '
    . $agent->res->status_line
    unless $agent->success;

is(
    $agent->content, q{Referer: ''},
    'First page gets sent with empty referrer'
);

$agent->get($url);
is( $agent->status, 200, 'Got second page' ) or diag $agent->res->message;
is(
    $agent->content, "Referer: '$url'",
    'Referer got sent for absolute url'
);

$agent->get('.');
is( $agent->status, 200, 'Got third page' ) or diag $agent->res->message;
is(
    $agent->content, "Referer: '$url'",
    'Referer got sent for relative url'
);

$agent->add_header( Referer => 'x' );
$agent->get($url);
is( $agent->status,  200, 'Got fourth page' ) or diag $agent->res->message;
is( $agent->content, q{Referer: 'x'}, 'Referer can be set to empty again' );

my $ref = 'This is not the referer you are looking for *jedi gesture*';
$agent->add_header( Referer => $ref );
$agent->get($url);
is( $agent->status,  200, 'Got fifth page' ) or diag $agent->res->message;
is( $agent->content, "Referer: '$ref'", 'Custom referer can be set' );

memory_cycle_ok( $agent, 'No memory cycles found' );

done_testing;
