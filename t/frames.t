#!perl -Tw

use warnings;
use strict;
use Test::More tests => 7;
use URI::file;
     
BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};  # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( "t/frames.html" )->as_string;

$mech->get( $uri );
ok( $mech->success, "Fetched $uri" ) or die "Can't get test page";

my $x;
$x = $mech->find_link();
isa_ok( $x, 'WWW::Mechanize::Link' );

my @links = $mech->find_all_links();
is( scalar @links, 2, "Only two links" );

my $link1 = $links[0];
is_deeply( [@{$link1}[0..3]], [ 'find_link.html', undef, 'top', 'frame' ], "First frame OK" );

my $link2 = $links[1];
is_deeply( [@{$link2}[0..3]], [ 'google.html', undef, 'bottom', 'frame' ], "Second frame OK" );
