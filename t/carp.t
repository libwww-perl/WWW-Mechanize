use warnings;
use strict;
use Test::More;

BEGIN {
    eval "use Test::Warn";
    plan skip_all => "Test::Warn required to test _carp" if $@;
    plan tests => 3;
}

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

warning_like {
    my $m = WWW::Mechanize->new;
    isa_ok( $m, 'WWW::Mechanize' );
    $m->_carp( "Something bad" );
} qr[Something bad.+carp.t.+line \d+], "Passes the message, and includes the filename and line number";

