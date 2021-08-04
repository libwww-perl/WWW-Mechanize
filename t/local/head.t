use warnings;
use strict;
use Test::More;

use lib qw( t t/local );
use LocalServer;

BEGIN {
    delete @ENV{ qw( IFS CDPATH ENV BASH_ENV ) };
    use_ok( 'WWW::Mechanize' );
}

my $server = LocalServer->spawn;
isa_ok( $server, 'LocalServer' );

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize', 'Created object' );

ok !$agent->base, 'Starting out with no ->base';
my $response = $agent->get($server->url);
isa_ok( $response, 'HTTP::Response' );
ok $agent->base, '... and now there is a ->base';

$agent->head( '/foo.html' );
ok !$agent->content, 'HEADing returns no content';
is my $filename = $agent->response->filename, 'foo.html', '... but the filename is set';

done_testing;