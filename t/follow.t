use warnings;
use strict;
use Test::More tests => 9;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize', 'Created object' );

my $response = $agent->get( "http://www.google.com/intl/en/" );
ok( $response->is_success, 'Got google' );

ok(! $agent->follow(99999), "Can't follow too-high-numbered link");
ok($agent->follow(1), "Can follow first link");
ok($agent->back(), "Can go back");

ok(! $agent->follow(qr/asdfghjksdfghj/), "Can't follow unlikely named link");
ok($agent->follow("Search"), "Can follow obvious named link");
ok($agent->back(), "Can still go back");
