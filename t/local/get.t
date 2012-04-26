#!perl

use warnings;
use strict;
use Test::More tests => 32;

use lib qw( t t/local );
use LocalServer;

BEGIN {
    use Tools;
}

BEGIN {
    delete @ENV{ qw( IFS CDPATH ENV BASH_ENV ) };
    use_ok( 'WWW::Mechanize' );
}

my $server = LocalServer->spawn;
isa_ok( $server, 'LocalServer' );

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize', 'Created object' );

my $response = $agent->get($server->url);
isa_ok( $response, 'HTTP::Response' );
isa_ok( $agent->response, 'HTTP::Response' );
ok( $response->is_success, 'Page read OK' );
ok( $agent->success, "Get webpage" );
is( $agent->ct, "text/html", "Got the content-type..." );
ok( $agent->is_html, "... and the is_html wrapper" );
is( $agent->title, 'WWW::Mechanize test page', 'Titles match' );

$agent->get( '/foo/' );
ok( $agent->success, 'Got the /foo' );
is( $agent->uri, sprintf('%sfoo/',$server->url), 'Got relative OK' );
ok( $agent->is_html,'Got HTML back' );
is( $agent->title, 'WWW::Mechanize test page', 'Got the right page' );

$agent->get( '../bar/' );
ok( $agent->success, 'Got the /bar page' );
is( $agent->uri, sprintf('%sbar/',$server->url), 'Got relative OK' );
ok( $agent->is_html, 'is HTML' );
is( $agent->title, 'WWW::Mechanize test page', 'Got the right page' );

$agent->get( 'basics.html' );
ok( $agent->success, 'Got the basics page' );
is( $agent->uri, sprintf('%sbar/basics.html',$server->url), 'Got relative OK' );
ok( $agent->is_html, 'is HTML' );
is( $agent->title, 'WWW::Mechanize test page', 'Title matches' );
like( $agent->content, qr/WWW::Mechanize test page/, 'Got the right page' );

$agent->get( './refinesearch.html' );
ok( $agent->success, 'Got the "refine search" page' );
is( $agent->uri, sprintf('%sbar/refinesearch.html',$server->url), 'Got relative OK' );
ok( $agent->is_html, 'is HTML' );
is( $agent->title, 'WWW::Mechanize test page', 'Title matches' );
like( $agent->content, qr/WWW::Mechanize test page/, 'Got the right page' );
my $rslength = do {use bytes; length $agent->content};

my $tempfile = './temp';
unlink $tempfile;
ok( !-e $tempfile, 'tempfile not there right now' );
$agent->get( './refinesearch.html', ':content_file'=>$tempfile );
ok( -e $tempfile, 'File exists' );
is( -s $tempfile, $rslength, 'Did all the bytes get saved?' );
unlink $tempfile;

SKIP: {
    skip 'Test::Memory::Cycle not installed', 1 unless $canTMC;

    memory_cycle_ok( $agent, 'Mech: no cycles' );
}
