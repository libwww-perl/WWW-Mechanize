#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 9;

BEGIN {
    use_ok( 'WWW::Mechanize::Link' );
}

my $link = WWW::Mechanize::Link->new( "url", "text", "name" );
isa_ok( $link, 'WWW::Mechanize::Link' );
is( scalar @$link, 3 );

# Test the new-style accessors
is( $link->url, "url" );
is( $link->text, "text" );
is( $link->name, "name" );

# Order of the parms in the blessed array is important for backwards
# compatibility.
is( $link->[0], 'url', 'parm 0 is url' );
is( $link->[1], 'text', 'parm 1 is text' );
is( $link->[2], 'name', 'parm 2 is name' );
