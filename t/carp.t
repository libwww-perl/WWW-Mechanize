use warnings;
use strict;
use Test::More;

BEGIN {
    eval "use Test::Warn";
    plan skip_all => "Test::Warn required to test _carp" if $@;
    plan tests => 4;
}

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $m = WWW::Mechanize->new;
isa_ok( $m, 'WWW::Mechanize' );

warning_like {
    $m->_carp( "Something bad" );
} qr[Something bad.+carp.t.+line \d+], "Passes the message, and includes the filename and line number";

warning_like {
    $m->quiet(1);
    $m->_carp( "Something bad" );
} undef, "Quiets correctly";
