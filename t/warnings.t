#!perl -T

use warnings;
use strict;

use Test::More;
use Test::Warnings qw( :all );
use WWW::Mechanize ();

UNKNOWN_ALIAS: {
    my $m = WWW::Mechanize->new;
    isa_ok( $m, 'WWW::Mechanize' );

    like warning {
        $m->agent_alias( 'Blongo' );
    }, qr/\AUnknown agent alias "Blongo"/, 'Unknown aliases squawk appropriately';
}

done_testing();
