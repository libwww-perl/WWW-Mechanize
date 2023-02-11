use warnings;
use strict;
use Test::More tests => 6;
use lib         qw( t/local );
use LocalServer ();

BEGIN {
    delete @ENV{qw( IFS CDPATH ENV BASH_ENV )};
    use_ok('WWW::Mechanize');
}

my $mech = WWW::Mechanize->new();
isa_ok( $mech, 'WWW::Mechanize' );
my $server = LocalServer->spawn();
isa_ok( $server, 'LocalServer' );

my $response = $mech->get( $server->url . 'encoding/euc-jp' );
ok( $mech->success, 'Fetched OK' );
is( $response->content_charset(), 'EUC-JP', 'got encoding enc-jp' );

$response = $mech->get( $server->url . 'quit_server' );
ok( $mech->success, 'Quit OK' );
