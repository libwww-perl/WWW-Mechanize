#!perl

use warnings;
use strict;
use Test::More tests => 6;

BEGIN {
    use_ok('WWW::Mechanize');
}

my $mech = WWW::Mechanize->new();
isa_ok( $mech, 'WWW::Mechanize' );
my $clone;

INITIAL_CLONE: {
    $mech->cookie_jar->set_cookie( 1, 2, 3, '/4', '5', 6, '7', 8, 9, 10 );
    my $old_cookies = $mech->cookie_jar->as_string;

    $clone = $mech->clone();
    isa_ok( $clone, 'WWW::Mechanize' );
    my $new_cookies = $clone->cookie_jar->as_string;

    is( $old_cookies, $new_cookies, 'Cookie jar contents are the same' );
}

COOKIE_SHARING: {

    # Now see if we're still working on the same jar
    $clone->cookie_jar->set_cookie(
        10, 20, 30, '/40', '50', 60, '70', 80,
        90, 10
    );
    my $old_cookies = $mech->cookie_jar->as_string;
    my $new_cookies = $clone->cookie_jar->as_string;

    is( $old_cookies, $new_cookies, 'Adding cookies adds to both jars' );
}

HEADERS_NOT_SHARING: {

    # headers should be independent
    $clone->add_header( foo => 'bar' );
    ok(
        not( $mech->{headers}{foo} ),
        'Adding headers does not add to both agents',
    );
}
