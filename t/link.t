#!perl -T

use warnings;
use strict;

use Test::More tests => 16;

BEGIN {
    use_ok( 'WWW::Mechanize::Link' );
}

my $link = WWW::Mechanize::Link->new( "url.html", "text", "name", "frame", "http://base.example.com/" );
isa_ok( $link, 'WWW::Mechanize::Link' );
is( scalar @$link, 5, "Should have five elements" );

# Test the new-style accessors
is( $link->url, "url.html", "url works" );
is( $link->text, "text", "text works" );
is( $link->name, "name", "name works" );
is( $link->tag, "frame", "frame works" );
is( $link->base, "http://base.example.com/", "base works" );

# Order of the parms in the blessed array is important for backwards
# compatibility.
is( $link->[0], 'url.html', 'parm 0 is url' );
is( $link->[1], 'text', 'parm 1 is text' );
is( $link->[2], 'name', 'parm 2 is name' );
is( $link->[3], 'frame', 'parm 3 is tag' );
is( $link->[4], 'http://base.example.com/', 'parm 4 is base' );

my $URI = $link->URI;
isa_ok( $URI, "URI::URL", "URI is proper type" );
is( $URI->rel, "url.html", "Short form of the url" );
is( $link->url_abs, "http://base.example.com/url.html", "url_abs works" );
