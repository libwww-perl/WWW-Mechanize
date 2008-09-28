#!perl -T

use warnings;
use strict;

use Test::More tests => 9;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

# XXX We need tests in here to verify that we're asking for gzip output

my $mech = WWW::Mechanize->new;
isa_ok( $mech, 'WWW::Mechanize', 'Created object' );
$mech->agent_alias( 'Linux Mozilla' );

my $first_page = 'http://www.computers4sure.com/';
$mech->get( $first_page );
is( $mech->response->code, 200, "Fetched $first_page" );
ok( $mech->content =~ /Support/, 'Found a likely word in the first page' );

my @links = $mech->find_all_links( url_regex => qr{product\.asp\?productid=} );
cmp_ok( scalar @links, '>', 10, 'Should have lots of product links' );

my $link = $links[@links/2]; # Pick one in the middle
isa_ok( $link, 'WWW::Mechanize::Link' );
my $link_str = $link->url;

# The problem we're having is that the 2nd get, following a link,
# comes back gzipped.
$mech->get( $link_str );
is( $mech->response->code, 200, "Fetched $link_str" );
ok( $mech->content =~ /Your price/i, 'Found a likely phrase in the second page' );

SKIP: {
    eval 'use Test::Memory::Cycle';
    skip 'Test::Memory::Cycle not installed', 1 if $@;

    memory_cycle_ok( $mech, 'No memory cycles found' );
}
