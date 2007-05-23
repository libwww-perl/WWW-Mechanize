#!perl -T

use warnings;
use strict;

use Test::More tests => 8;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new;
isa_ok( $mech, 'WWW::Mechanize', 'Created object' );
$mech->agent_alias('Linux Mozilla');

$mech->get( 'http://www.computers4sure.com/' );
ok( $mech->content =~ /Support/, 'Found a likely word.' );

my @links = $mech->find_all_links( url_regex => qr{product\.asp\?productid=} );
cmp_ok( scalar @links, '>', 10, 'Should have lots of product links' );

my $link = $links[@links/2]; # Pick one in the middle
isa_ok( $link, 'WWW::Mechanize::Link' );

my $link_str = $link->url;
$mech->get( $link_str );
is( $mech->response->code, 200, "Fetched $link_str" );
ok( $mech->content =~ /Your price/i, 'Found a likely phrase' );
#print $mech->content;

SKIP: {
    eval "use Test::Memory::Cycle";
    skip "Test::Memory::Cycle not installed", 1 if $@;

    memory_cycle_ok( $mech, "No memory cycles found" );
}

