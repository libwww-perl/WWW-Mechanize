#!/usr/bin/perl
   
use warnings;
use strict;
use Test::More tests => 7;
use URI::file;
     
BEGIN {
    use_ok( 'WWW::Mechanize' );
}
   
my $t = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $t, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( "t/frames.html" )->as_string;

$t->get( $uri );
ok( $t->success, "Fetched $uri" ) or die "Can't get test page";

my $x;
$x = $t->find_link();
isa_ok( $x, 'WWW::Mechanize::Link' );

my @links = $t->find_all_links();
is( scalar @links, 2, "Only two links" );
is_deeply( $links[0], [ 'find_link.html', undef, 'top', 'frame' ], "First frame OK" );
is_deeply( $links[1], [ 'google.html', undef, 'bottom', 'frame' ], "Second frame OK" );
