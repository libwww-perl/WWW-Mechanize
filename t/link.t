#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 13;

BEGIN {
    use_ok( 'WWW::Mechanize::Link' );
}

my $link = WWW::Mechanize::Link->new( "base", "url", "text", "name", "frame" );
isa_ok( $link, 'WWW::Mechanize::Link' );
is( scalar @$link, 5, "Should have four elements" );

# Test the new-style accessors
is( $link->url, "url" );
is( $link->text, "text" );
is( $link->name, "name" );
is( $link->tag, "frame" );
is( $link->base, "base" );

# Order of the parms in the blessed array is important for backwards
# compatibility.
is( $link->[0], 'url', 'parm 0 is url' );
is( $link->[1], 'text', 'parm 1 is text' );
is( $link->[2], 'name', 'parm 2 is name' );
is( $link->[3], 'frame', 'parm 3 is tag' );
is( $link->[4], 'base', 'parm 4 is base' );
