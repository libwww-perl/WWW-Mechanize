#!perl -T

use warnings;
use strict;
use Test::More;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception required to test die" if $@;
    plan tests => 5;
}

BEGIN {
    use_ok( 'WWW::Mechanize' );
}


CHECK_DEATH: {
    my $m = WWW::Mechanize->new;
    isa_ok( $m, 'WWW::Mechanize' );

    dies_ok {
        $m->die( "OH NO!  ERROR!" );
    } "Expecting to die";
}

CHECK_LIVING: {
    my $m = WWW::Mechanize->new( onerror => undef );
    isa_ok( $m, 'WWW::Mechanize' );

    lives_ok {
        $m->die( "OH NO!  ERROR!" );
    } "Expecting to die";
}
