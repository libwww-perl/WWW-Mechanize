use warnings;
use strict;
use Test::More;

use constant NONEXISTENT => "http://sdflkjsdflkjs34.xx-nonexistent";

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception required to test autocheck" if $@;
    plan tests => 5;
}

BEGIN { delete $ENV{ qw( http_proxy HTTP_PROXY ) }; }
BEGIN {
    use_ok( 'WWW::Mechanize' );
}

AUTOCHECK_OFF: {
    my $mech = WWW::Mechanize->new;
    isa_ok( $mech, 'WWW::Mechanize' );

    $mech->get( NONEXISTENT );
    ok( !$mech->success, "Didn't fetch, but didn't die, either" );
}

AUTOCHECK_ON: {
    my $mech = WWW::Mechanize->new( autocheck => 1 );
    isa_ok( $mech, 'WWW::Mechanize' );

    dies_ok {
        $mech->get( NONEXISTENT );
    } "Mech would die 4 u";
}
