#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 16;
use URI::file;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $t = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $t, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( "t/find_link.html" )->as_string;

$t->get( $uri );
ok( $t->success, "Fetched $uri" ) or die "Can't get test page";

my $x;
$x = $t->find_link();
is( $x->[0], "http://cnn.com/", "First link on the page" );

$x = $t->find_link( text => "CPAN A" );
is( $x->[0], "http://a.cpan.org/", "First CPAN link" );

$x = $t->find_link( url => "CPAN" );
ok( !defined $x, "No url matching CPAN" );

$x = $t->find_link( text_regex => "CPAN", n=>3 );
is( $x->[0], "http://c.cpan.org/", "3rd CPAN text" );

$x = $t->find_link( text => "CPAN", n=>34 );
ok( !defined $x, "No 34th CPAN text" );

$x = $t->find_link( text_regex => "(?i:cpan)" );
is( $x->[0], "http://a.cpan.org/", "Got 1st cpan via regex" );

$x = $t->find_link( text_regex => qr/cpan/i );
is( $x->[0], "http://a.cpan.org/", "Got 1st cpan via regex" );

$x = $t->find_link( text_regex => qr/cpan/i, n=>153 );
ok( !defined $x, "No 153rd cpan link" );

$x = $t->find_link( url => "http://b.cpan.org/" );
is( $x->[0], "http://b.cpan.org/", "Got b.cpan.org" );

$x = $t->find_link( url => "http://b.cpan.org", n=>2 );
ok( !defined $x, "Not a second b.cpan.org" );

$x = $t->find_link( url_regex => qr/[b-d]\.cpan\.org/, n=>2 );
is( $x->[0], "http://c.cpan.org/", "Got c.cpan.org" );

my @wanted_links= (
   [ "http://a.cpan.org/", "CPAN A", undef ], 
   [ "http://b.cpan.org/", "CPAN B", undef ], 
   [ "http://c.cpan.org/", "CPAN C", "bongo" ], 
   [ "http://d.cpan.org/", "CPAN D", undef ], 
);
my @links = $t->find_all_links( text_regex => qr/CPAN/ );
ok( eq_array( \@links, \@wanted_links ), "Correct links came back" );

my $linkref = $t->find_all_links( text_regex => qr/CPAN/ );
ok( eq_array( $linkref, \@wanted_links ), "Correct links came back" );
