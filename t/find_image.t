#!perl -T

use warnings;
use strict;

use Test::More tests => 17;
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
is( scalar @images, 3, 'Exactly three images' );

my $first = $images[0];
is( $first->url, 'wango.jpg', 'Got the first image' );
is( $first->tag, 'img', 'img tag' );
is( $first->alt, 'The world of the wango' );

my $second = $images[1];
is( $second->url, 'bongo.gif', 'Got the second image' );
is( $second->tag, 'input', 'input tag' );
is( $second->alt, undef, 'alt' );
is( $second->height, 142, 'height' );
is( $second->width, 43, 'width' );

my $third = $images[2];
is( $third->url, 'linked.gif', 'Got the third image' );
is( $third->tag, 'img', 'input tag' );
is( $third->alt, undef, 'alt' );

is_deeply( \@images, [$mech->images] );
