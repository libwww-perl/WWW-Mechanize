#!perl -Tw

use warnings;
use strict;

use Test::More tests=>15;
use URI::file;

BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};  # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( "t/image-parse.html" )->as_string;

$mech->get( $uri );
ok( $mech->success, "Fetched $uri" ) or die "Can't get test page";

my @images = $mech->images;
is( scalar @images, 3, "Only two images" );

my $first = $images[0];
is( $first->tag, "img", "img tag" );
is( $first->url, "wango.jpg" );
is( $first->alt, "The world of the wango" );

my $second = $images[1];
is( $second->tag, "input", "input tag" );
is( $second->url, "bongo.gif" );
is( $second->alt, undef, "alt" );
is( $second->height, 142, "height" );
is( $second->width, 43, "width" );

my $third = $images[2];
is( $third->url, "linked.gif", "Got the third image" );
is( $third->tag, "img", "input tag" );
is( $third->alt, undef, "alt" );
