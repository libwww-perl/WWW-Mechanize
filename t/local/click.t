#!perl

use warnings;
use strict;
use lib 't/local';
use LocalServer;
use Test::More tests => 10;

BEGIN {
    delete @ENV{ grep { lc eq 'http_proxy' } keys %ENV };
    delete @ENV{ qw( IFS CDPATH ENV BASH_ENV ) };
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new();
isa_ok( $mech, 'WWW::Mechanize', 'Created the object' );

my $server = LocalServer->spawn();
isa_ok( $server, 'LocalServer' );

my $response = $mech->get( $server->url );
isa_ok( $response, 'HTTP::Response', 'Got back a response' );
ok( $response->is_success, 'Got URL' ) or die q{Can't even fetch local url};
ok( $mech->is_html, 'Local page is HTML' );
my @forms = $mech->forms;
is( scalar @forms, 1, 'Only one form' );

$mech->field(query => 'foo'); # Filled the 'q' field

$response = $mech->click('submit');
isa_ok( $response, 'HTTP::Response', 'Got back a response' );
ok( $response->is_success, q{Can click 'Go' ('Google Search' button)} );

is( $mech->field('query'),'foo', 'Filled field correctly');

