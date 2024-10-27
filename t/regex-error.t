#!perl

use warnings;
use strict;

use Test::More;
use Test::Warnings qw(:all);
use WWW::Mechanize ();

my $m = WWW::Mechanize->new;
isa_ok( $m, 'WWW::Mechanize' );

like warning {
    $m->find_link( link_regex => 'foo' );
},
    qr[Unknown link-finding parameter "link_regex".+line \d+],
    'Passes message, and includes the line number';

like warning {
    $m->find_link( url_regex => 'foo' );
},
    qr[foo passed as url_regex is not a regex.+line \d+],
    'Passes message, and includes the line number';

done_testing();
