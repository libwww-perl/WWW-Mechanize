use utf8;
use warnings;
use strict;
use Test::More tests => 5;
use lib 't/local';
use LocalServer;

BEGIN {
    delete @ENV{ qw( IFS CDPATH ENV BASH_ENV ) };
    use_ok( 'WWW::Mechanize' );
}

my $server = LocalServer->spawn( file => 't/local/nonascii.html' );
isa_ok( $server, 'LocalServer' );

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize', 'Created object' );
$agent->quiet(0);

$agent->get( $server->url );
ok( $agent->success, 'Got some page' );

# \321\202 is \x{442}
$agent->field("ValueOf'CF.{\321\202}'", "\321\201");
is($agent->value("ValueOf'CF.{\321\202}'"), "\321\201", 'set utf value');
