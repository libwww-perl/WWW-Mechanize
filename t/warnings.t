#!perl -T

use warnings;
use strict;
use Test::More;

BEGIN {
    eval "use Test::Warn";
    plan skip_all => "Test::Warn required to test warnings" if $@;
    plan tests => 3;
}

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

UNKNOWN_ALIAS: {
    my $m = WWW::Mechanize->new;
    isa_ok( $m, 'WWW::Mechanize' );

    warning_is {
        $m->agent_alias( "Blongo" );
    } 'Unknown agent alias "Blongo"', "Unknown aliases squawk appropriately";
}
