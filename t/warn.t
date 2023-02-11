#!perl -T

use warnings;
use strict;

use Test::Warnings qw( :all );
use Test::More;
use WWW::Mechanize ();

my $m = WWW::Mechanize->new;
isa_ok( $m, 'WWW::Mechanize' );

like warning {
    $m->warn('Something bad');
},
    qr[Something bad.+line \d+],
    'Passes the message, and includes the line number';

is join(
    '',
    warnings {
        $m->quiet(1);
        $m->warn('Something bad');
    }
    ),
    '', 'Quiets correctly';

my $hushed = WWW::Mechanize->new( quiet => 1 );
isa_ok( $hushed, 'WWW::Mechanize' );
is join(
    '',
    warnings {
        $hushed->warn('Something bad');
    }
    ),
    '', 'Quiets correctly';

done_testing();
