#!perl -T

use warnings;
use strict;
use Test::More tests => 5;

use constant START => 'http://en.wikipedia.org/';

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new;
isa_ok( $mech, 'WWW::Mechanize', 'Created object' );
$mech->agent_alias( 'Windows IE 6' ); # Wikipedia 403s out obvious bots

$mech->get( START );

ok( $mech->success, 'Got a page' );
my @links = $mech->links();
cmp_ok( scalar @links, '>', 50, 'There are well over 50 links on the front page' );

SKIP: {
    eval "use Test::Memory::Cycle";
    skip "Test::Memory::Cycle not installed", 1 if $@;

    memory_cycle_ok( $mech, "No memory cycles found" );
}

