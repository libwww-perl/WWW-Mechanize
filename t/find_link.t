#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 14;
use URI::file;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $t = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $t, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( "t/find_link.html" );

my $response = $t->get( $uri );
ok( $response->is_success, "Fetched $uri" ) or die "Can't get test page";

my $x;
$x = $t->find_link();
is( $x->[0], "http://cnn.com/", "First link on the page" );

$x = $t->find_link( text => "CPAN" );
is( $x->[0], "http://a.cpan.org/", "First CPAN link" );

$x = $t->find_link( url => "CPAN" );
ok( !defined $x, "No url matching CPAN" );

$x = $t->find_link( text => "CPAN", n=>3 );
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

