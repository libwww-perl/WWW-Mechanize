#!perl -T

use warnings;
use strict;
use Test::More;

BEGIN {
    eval 'use Test::Warn';
    plan skip_all => "Test::Warn required to test $0" if $@;
    plan tests => 4;
}

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $m = WWW::Mechanize->new;
isa_ok( $m, 'WWW::Mechanize' );

warning_like {
    $m->find_link( link_regex => 'foo' );
} qr[Unknown link-finding parameter "link_regex".+line \d+], 'Passes message, and includes the line number';

warning_like {
    $m->find_link( url_regex => 'foo' );
} qr[foo passed as url_regex is not a regex.+line \d+], 'Passes message, and includes the line number';

