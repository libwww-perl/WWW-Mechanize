use warnings;
use strict;
use Test::More tests => 14;
use constant START => 'http://www.google.com/intl/en/';

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize', 'Created object' );

my $response = $agent->get( START );
ok( $response->is_success, 'Got some page' );
is( $agent->uri, START, 'Got Google' );

ok(! $agent->follow(99999), "Can't follow too-high-numbered link");

ok($agent->follow(1), "Can follow first link");
isnt( $agent->uri, START, 'Need to be on a separate page' );

ok($agent->back(), "Can go back");
is( $agent->uri, START, 'Back at the first page' );

ok(! $agent->follow(qr/asdfghjksdfghj/), "Can't follow unlikely named link");

ok($agent->follow("Search"), "Can follow obvious named link");
isnt( $agent->uri, START, 'Need to be on a separate page' );

ok($agent->back(), "Can still go back");
is( $agent->uri, START, 'Back at the start page again' );
