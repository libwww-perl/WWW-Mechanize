#!perl -T

use warnings;
use strict;

use Test::Fatal qw( exception );
use Test::More;
use WWW::Mechanize ();

my $bad_url = "file:///foo.foo.xx.random";

AUTOCHECK_OFF: {
    my $mech = WWW::Mechanize->new( autocheck => 0 );
    $mech->get( $bad_url );
    ok( !$mech->success, qq{Didn't fetch $bad_url, but didn't die, either} );
}

AUTOCHECK_ON: {
    like(
        exception { WWW::Mechanize->new->get($bad_url) },
        qr/Error GETing/,
        qq{Couldn't fetch $bad_url, and died as a result}
    );
}

done_testing();
