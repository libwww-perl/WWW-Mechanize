#!perl -T

use warnings;
use strict;

use Test::Warn qw( warning_like );
use Test::More;
use WWW::Mechanize ();

my $m = WWW::Mechanize->new;
isa_ok( $m, 'WWW::Mechanize' );

warning_like {
    $m->warn( 'Something bad' );
} qr[Something bad.+line \d+], 'Passes the message, and includes the line number';

warning_like {
    $m->quiet(1);
    $m->warn( 'Something bad' );
} undef, 'Quiets correctly';

my $hushed = WWW::Mechanize->new( quiet => 1 );
isa_ok( $hushed, 'WWW::Mechanize' );
warning_like {
    $hushed->warn( 'Something bad' );
} undef, 'Quiets correctly';

done_testing();
