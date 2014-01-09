use warnings;
use strict;
use Test::More tests => 28;
use lib 't/local';
use LocalServer;

BEGIN {
    delete @ENV{ qw( IFS CDPATH ENV BASH_ENV ) };
    use_ok( 'WWW::Mechanize' );
}

my $server = LocalServer->spawn;
isa_ok( $server, 'LocalServer' );

my $agent = WWW::Mechanize->new( autocheck => 0 );
isa_ok( $agent, 'WWW::Mechanize', 'Created object' );
$agent->quiet(1);

my $response;

$agent->get( $server->url );
ok( $agent->success, 'Got some page' );
is( $agent->uri, $server->url, 'Got local server page' );

$response = $agent->follow_link( n => 99999 );
ok( !$response, q{Can't follow too-high-numbered link});

$response = $agent->follow_link( n => 1 );
isa_ok( $response, 'HTTP::Response', 'Gives a response' );
isnt( $agent->uri, $server->url, 'Need to be on a separate page' );

ok($agent->back(), 'Can go back');
is( $agent->uri, $server->url, 'Back at the first page' );

ok(! $agent->follow_link( text_regex => qr/asdfghjksdfghj/ ), "Can't follow unlikely named link");

ok($agent->follow_link( text => 'Link /foo' ), 'Can follow obvious named link');
isnt( $agent->uri, $server->url, 'Need to be on a separate page' );

ok($agent->back(), 'Can still go back');
ok($agent->follow_link( text_regex=>qr/L\x{f6}schen/ ), 'Can follow link with o-umlaut');
isnt( $agent->uri, $server->url, 'Need to be on a separate page' );

ok($agent->back(), 'Can still go back');
ok($agent->follow_link( text_regex=>qr/St\x{f6}sberg/ ), q{Can follow link with o-umlaut, when it's encoded in the HTML, but not in "follow"});
isnt( $agent->uri, $server->url, 'Need to be on a separate page' );

ok($agent->back(), 'Can still go back');
is( $agent->uri, $server->url, 'Back at the start page again' );

$response = $agent->follow_link( text_regex => qr/Snargle/ );
ok( !$response, q{Couldn't find it} );

ok($agent->follow_link( url => '/foo' ), 'can follow url');
isnt( $agent->uri, $server->url, 'Need to be on a separate page' );
ok($agent->back(), 'Can still go back');

ok(!$agent->follow_link( url => '/notfoo' ), "can't follow wrong url");
is( $agent->uri, $server->url, 'Needs to be on the same page' );
eval {$agent->follow_link( '/foo' )};
like($@, qr/Needs to get key-value pairs of parameters.*follow\.t/, "Invalid parameter passing gets better error message");

