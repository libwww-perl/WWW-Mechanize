use warnings;
use strict;
use Test::More tests => 24;

use lib 't/lib';
use Test::HTTP::LocalServer;
my $server = Test::HTTP::LocalServer->spawn;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize', 'Created object' );

ok($agent->get($server->url)->is_success, "Get webpage");
isa_ok($agent->uri, "URI", "Set uri");
ok( $agent->is_html );
is( $agent->title, "WWW::Mechanize::Shell test page" );

ok( $agent->get( '/foo/' )->is_success, 'Got the /foo' );
is( $agent->uri, sprintf('%sfoo/',$server->url), "Got relative OK" );
ok( $agent->is_html,"Got HTML back" );
is( $agent->title, "WWW::Mechanize::Shell test page", "Got the right page" );

ok( $agent->get( '../bar/' )->is_success, 'Got the /bar page' );
is( $agent->uri, sprintf('%sbar/',$server->url), "Got relative OK" );
ok( $agent->is_html );
is( $agent->title, "WWW::Mechanize::Shell test page", "Got the right page" );

ok( $agent->get( 'basics.html' )->is_success, 'Got the basics page' );
is( $agent->uri, sprintf('%sbar/basics.html',$server->url), "Got relative OK" );
ok( $agent->is_html );
is( $agent->title, "WWW::Mechanize::Shell test page" );
like( $agent->content, qr/WWW::Mechanize::Shell test page/, "Got the right page" );

ok( $agent->get( './refinesearch.html' )->is_success, 'Got the "refine search" page' );
is( $agent->uri, sprintf('%sbar/refinesearch.html',$server->url), "Got relative OK" );
ok( $agent->is_html );
is( $agent->title, "WWW::Mechanize::Shell test page" );
like( $agent->content, qr/WWW::Mechanize::Shell test page/, "Got the right page" );

#ok( $agent->get( "http://www.google.com/images/logo.gif" )->is_success, "Got the logo" );
#ok( !$agent->is_html );

