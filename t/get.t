use warnings;
use strict;
use Test::More tests => 17;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize', 'Created object' );

ok($agent->get("http://www.google.com"), "Get google webpage");
isa_ok($agent->{uri}, "URI", "Set uri");
isa_ok($agent->{req}, 'HTTP::Request', "req should be a HTTP::Request");

ok( $agent->get( '/news/' ), 'Got the news' );
is( $agent->{uri}, 'http://www.google.com/news/', "Got relative OK" );
like( $agent->{content}, qr/News and Resources/, "Got the right page" );

ok( $agent->get( '../help/' ), 'Got the help page' );
is( $agent->{uri}, 'http://www.google.com/help/', "Got relative OK" );
like( $agent->{content}, qr/Google Help Central/, "Got the right page" );

ok( $agent->get( 'basics.html' ), 'Got the basics page' );
is( $agent->{uri}, 'http://www.google.com/help/basics.html', "Got relative OK" );
like( $agent->{content}, qr/Basics of Google Search/, "Got the right page" );

ok( $agent->get( './refinesearch.html' ), 'Got the "refine search" page' );
is( $agent->{uri}, 'http://www.google.com/help/refinesearch.html', "Got relative OK" );
like( $agent->{content}, qr/Advanced Search Made Easy/, "Got the right page" );
