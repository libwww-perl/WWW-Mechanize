#!perl -Tw

use warnings;
use strict;

use Test::More tests => 31;
use URI::file;

BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};  # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( 't/image-parse.html' )->as_string;

$mech->get( $uri );
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

my @images;
eval { @images = $mech->find_all_images(); };
is($@,'','survived eval');
is( scalar @images, 5, 'Exactly four images' );

my $first = $images[0];
is( $first->url, '/Images/bg-gradient.png', 'Got the fourth image' );
is( $first->tag, 'css', 'css tag' );
is( $first->alt, undef, 'alt' );

my $second = $images[1];
is( $second->url, 'wango.jpg', 'Got the first image' );
is( $second->tag, 'img', 'img tag' );
is( $second->alt, 'The world of the wango' );

my $third = $images[2];
is( $third->url, 'bongo.gif', 'Got the second image' );
is( $third->tag, 'input', 'input tag' );
is( $third->alt, undef, 'alt' );
is( $third->height, 142, 'height' );
is( $third->width, 43, 'width' );

my $fourth = $images[3];
is( $fourth->url, 'linked.gif', 'Got the third image' );
is( $fourth->tag, 'img', 'input tag' );
is( $fourth->alt, undef, 'alt' );

my $fifth = $images[4];
is( $fifth->url, 'images/logo.png', 'Got the fifth image' );
is( $fifth->tag, 'css', 'css tag' );
is( $fifth->alt, undef, 'alt' );

is_deeply( \@images, [$mech->images] );

# find image in css
$uri = URI::file->new_abs( 't/image-parse.css' )->as_string;

$mech->get( $uri );
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

eval { @images = $mech->find_all_images(); };
is($@,'','survived eval');
is( scalar @images, 2, 'Exactly two images' );

$second = $images[0];
is( $second->url, '/Images/bg-gradient.png', 'Got the first image' );
is( $second->tag, 'css', 'css tag' );
is( $second->alt, undef, 'alt' );

$third = $images[1];
is( $third->url, 'images/logo.png', 'Got the second image' );
is( $third->tag, 'css', 'css tag' );
