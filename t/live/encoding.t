#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 5;
use Encode;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new;
isa_ok( $mech, 'WWW::Mechanize' );

my @pairs = [
    'http://del.icio.us/'    => 'utf-8',
    'http://www.yahoo.co.jp' => 'euc-jp',
];

for my $pair ( @pairs ) {
    my ( $url, $want_encoding ) = @{$pair};

    $mech->get( $url );
    is( $mech->response->code, 200 );

    like( $mech->res->encoding, qr/$want_encoding/i, "Got encoding $want_encoding" );
    ok( Encode::is_utf8( $mech->content ) );
}
