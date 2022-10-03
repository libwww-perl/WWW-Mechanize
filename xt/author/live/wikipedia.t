#!perl -T

use warnings;
use strict;

use constant LANGUAGES => qw( en it ja es nl pl );

use Test::RequiresInternet( 'wikipedia.org' => 443 );
use Test::Needs 'LWP::Protocol::https';
use Test::More;
use WWW::Mechanize ();

use lib 't';

BEGIN {
    use Tools qw( $canTMC memory_cycle_ok );
}

my $mech = WWW::Mechanize->new;

$mech->agent_alias('Windows IE 6');    # Wikipedia 403s out obvious bots

for my $lang (LANGUAGES) {
    my $start = "https://$lang.wikipedia.org/";

    $mech->get($start);

    ok( $mech->success, "Got $start" );
    my @links = $mech->links();
    cmp_ok( scalar @links, '>', 50, "Over 50 links on $start" );
}

SKIP: {
    skip 'Test::Memory::Cycle not installed', 1 unless $canTMC;

    memory_cycle_ok( $mech, 'No memory cycles found' );
}

done_testing();
