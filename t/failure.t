use warnings;
use strict;
use Test::More tests => 8;

use lib 't/lib';
use Test::HTTP::LocalServer;
my $server = Test::HTTP::LocalServer->spawn;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize' );

my $url = $server->url;
$agent->get( $url );
ok( $agent->success, "Get first webpage" );
isa_ok($agent->uri, "URI", "Set uri");
ok( $agent->is_html );
is( $agent->title, "WWW::Mechanize::Shell test page" );

$agent->get( "http://frangotronimon.com.uk:8001/nonesuch/nada/zero/foo.html" );
ok( !$agent->success, "Didn't get fake page" );
is( $agent->uri, $url, "Old URI still in place" );
