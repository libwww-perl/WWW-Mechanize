use warnings;
use strict;
use Test::More tests => 29;

use lib 't/lib';
use Test::HTTP::LocalServer;
my $server = Test::HTTP::LocalServer->spawn;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize', 'Created object' );

my $response = $agent->get($server->url);
isa_ok( $response, 'HTTP::Response' );
ok( $response->is_success );
ok( $agent->success, "Get webpage" );
is( ref $agent->uri, "", "URI should be a string, not an object" );
ok( $agent->is_html );
is( $agent->title, "WWW::Mechanize::Shell test page" );

$agent->get( '/foo/' );
ok( $agent->success, 'Got the /foo' );
is( $agent->uri, sprintf('%sfoo/',$server->url), "Got relative OK" );
ok( $agent->is_html,"Got HTML back" );
is( $agent->title, "WWW::Mechanize::Shell test page", "Got the right page" );

$agent->get( '../bar/' );
ok( $agent->success, 'Got the /bar page' );
is( $agent->uri, sprintf('%sbar/',$server->url), "Got relative OK" );
ok( $agent->is_html );
is( $agent->title, "WWW::Mechanize::Shell test page", "Got the right page" );

$agent->get( 'basics.html' );
ok( $agent->success, 'Got the basics page' );
is( $agent->uri, sprintf('%sbar/basics.html',$server->url), "Got relative OK" );
ok( $agent->is_html );
is( $agent->title, "WWW::Mechanize::Shell test page" );
like( $agent->content, qr/WWW::Mechanize::Shell test page/, "Got the right page" );

$agent->get( './refinesearch.html' );
ok( $agent->success, 'Got the "refine search" page' );
is( $agent->uri, sprintf('%sbar/refinesearch.html',$server->url), "Got relative OK" );
ok( $agent->is_html );
is( $agent->title, "WWW::Mechanize::Shell test page" );
like( $agent->content, qr/WWW::Mechanize::Shell test page/, "Got the right page" );
my $rslength = length $agent->content;

my $tempfile = "./temp";
unlink $tempfile;
ok( !-e $tempfile, "tempfile isn't there right now" );
$agent->get( './refinesearch.html', ":content_file"=>$tempfile );
ok( -e $tempfile );
is( -s $tempfile, $rslength, "Did all the bytes get saved?" );
unlink $tempfile;
