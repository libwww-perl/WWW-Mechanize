#!perl -Tw

use warnings;
use strict;

use Test::More tests=>23;

BEGIN {
    use_ok( 'WWW::Mechanize::Link' );
}

OLD_API: {
    my $link =
        WWW::Mechanize::Link->new(
            "url.html", "text", "name", "frame", "http://base.example.com/", { alt => 'alt text' } );

    isa_ok( $link, 'WWW::Mechanize::Link' );
    is( scalar @$link, 6, "Should have five elements" );

    # Test the new-style accessors
    is( $link->url, "url.html", "url() works" );
    is( $link->text, "text", "text() works" );
    is( $link->name, "name", "name() works" );
    is( $link->tag, "frame", "tag() works" );
    is( $link->base, "http://base.example.com/", "base() works" );
    is( $link->attrs->{alt}, "alt text", "attrs() works" );

    # Order of the parms in the blessed array is important for backwards compatibility.
    is( $link->[0], 'url.html', 'parm 0 is url' );
    is( $link->[1], 'text', 'parm 1 is text' );
    is( $link->[2], 'name', 'parm 2 is name' );
    is( $link->[3], 'frame', 'parm 3 is tag' );
    is( $link->[4], 'http://base.example.com/', 'parm 4 is base' );

    my $URI = $link->URI;
    isa_ok( $URI, "URI::URL", "URI is proper type" );
    is( $URI->rel, "url.html", "Short form of the url" );
    is( $link->url_abs, "http://base.example.com/url.html", "url_abs works" );
}

NEW_API: {
    # test new style API
    my $link = WWW::Mechanize::Link->new( {
        url  => 'url.html',
        text => "text",
        name => "name",
        tag  => "frame",
        base => "http://base.example.com/",
        attrs => { alt =>  "alt text" },
    } );

    is( $link->url, "url.html", "url() works" );
    is( $link->text, "text", "text() works" );
    is( $link->name, "name", "name() works" );
    is( $link->tag, "frame", "tag() works" );
    is( $link->base, "http://base.example.com/", "base() works" );
    is( $link->attrs->{alt}, "alt text", "attrs() works" );
}
