use warnings;
use strict;
use Test::More tests => 4;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $agent = WWW::Mechanize->new;
isa_ok( $agent, "WWW::Mechanize", "Created agent" );

$agent->add_header(foo => 'bar');
is($WWW::Mechanize::headers{'foo'}, 'bar', "set header");

SKIP: {
    eval "use Test::Memory::Cycle";
    skip "Test::Memory::Cycle not installed", 1 if $@;

    memory_cycle_ok( $agent, "No memory cycles found" );
}
