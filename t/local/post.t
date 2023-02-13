use warnings;
use strict;
use Test::More tests => 5;

use lib qw( t/local );
use LocalServer ();

BEGIN {
    delete @ENV{ qw( IFS CDPATH ENV BASH_ENV ) };
    use_ok( 'WWW::Mechanize' );
}

my $server = LocalServer->spawn;
isa_ok( $server, 'LocalServer' );

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize', 'Created object' );

# GET with full URL to set the base
$agent->get($server->url);
ok( $agent->success, "Get webpage" );

# POST with relative URL
$agent->post('/post');
ok( $agent->success, "Post webpage" );
