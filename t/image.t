#!perl -Tw

use warnings;
use strict;

use Test::More tests=>10;

BEGIN {
    use_ok( 'WWW::Mechanize::Image' );
}

# test new style API
my $link = WWW::Mechanize::Image->new( {
    url  => 'url.html',
    base => "http://base.example.com/",
    name => "name",
    alt  => "alt",
    tag  => "a",
    height => 2112,
    width => 5150,
} );

is( $link->url, "url.html", "url() works" );
is( $link->base, "http://base.example.com/", "base() works" );
is( $link->name, "name", "name() works" );
is( $link->alt, "alt", "alt() works" );
is( $link->tag, "a", "tag() works" );
is( $link->height, 2112, "height works" );
is( $link->width, 5150, "width works" );
is( $link->url_abs, "http://base.example.com/url.html", "url_abs works" );
isa_ok( $link->URI, "URI::URL", "Returns an object" );
