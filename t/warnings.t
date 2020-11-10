#!perl -T

use warnings;
use strict;

use Test::More;
use Test::Warn qw( warning_is );
use WWW::Mechanize ();

UNKNOWN_ALIAS: {
    my $m = WWW::Mechanize->new;
    isa_ok( $m, 'WWW::Mechanize' );

    warning_is {
        $m->agent_alias( 'Blongo' );
    } 'Unknown agent alias "Blongo"', 'Unknown aliases squawk appropriately';
}

done_testing();
