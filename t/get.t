use warnings;
use strict;
use Test::More tests => 26;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize', 'Created object' );

ok($agent->get("http://www.google.com/intl/en/")->is_success, "Get google webpage");
isa_ok($agent->uri, "URI", "Set uri");
ok( $agent->is_html );
is( $agent->title, "Google" );

ok( $agent->get( '/news/' )->is_success, 'Got the news' );
is( $agent->uri, 'http://www.google.com/news/', "Got relative OK" );
ok( $agent->is_html );
is( $agent->title, "News and Resources", "Got the right page" );

ok( $agent->get( '../help/' )->is_success, 'Got the help page' );
is( $agent->uri, 'http://www.google.com/help/', "Got relative OK" );
ok( $agent->is_html );
is( $agent->title, "Google Help Central", "Got the right page" );

ok( $agent->get( 'basics.html' )->is_success, 'Got the basics page' );
is( $agent->uri, 'http://www.google.com/help/basics.html', "Got relative OK" );
ok( $agent->is_html );
is( $agent->title, "Google Help" );
like( $agent->content, qr/Basics of Google Search/, "Got the right page" );

ok( $agent->get( './refinesearch.html' )->is_success, 'Got the "refine search" page' );
is( $agent->uri, 'http://www.google.com/help/refinesearch.html', "Got relative OK" );
ok( $agent->is_html );
is( $agent->title, "Google Help" );
like( $agent->content, qr/Advanced Search Made Easy/, "Got the right page" );

ok( $agent->get( "http://www.google.com/images/logo.gif" )->is_success, "Got the logo" );
ok( !$agent->is_html );
