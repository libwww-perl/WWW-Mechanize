#!perl -Tw

use warnings;
use strict;

use Test::More tests => 5;

BEGIN {
    use_ok( 'WWW::Mechanize::Link' );
}

NO_BASE: {
    my $link = WWW::Mechanize::Link->new( "url.html", "Click here", undef, undef );
    isa_ok( $link, "WWW::Mechanize::Link", "constructor OK" );

    my $URI = $link->URI;
    isa_ok( $URI, "URI::URL", "URI is proper type" );
    is( $URI->rel, "url.html", "Short form of the url" );
    is( $link->url_abs, "url.html", "url_abs works" );
}
