#!perl -T

use warnings;
use strict;

use Test::More tests => 30;
use URI::file;

BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};  # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( 't/image-parse.html' )->as_string;

$mech->get( $uri );
ok( $mech->success, "Fetched $uri" ) or die 'Can\'t get test page';

my @images = $mech->images;
is( scalar @images, 7, 'Only seven images' );

my $first = $images[0];
is( $first->tag, 'img', 'img tag' );
is( $first->url, 'wango.jpg', 'URL matches' );
is( $first->alt, 'The world of the wango', 'alt matches' );

my $second = $images[1];
is( $second->tag, 'input', 'input tag' );
is( $second->url, 'bongo.gif', 'URL matches' );
is( $second->alt, undef, 'alt matches' );
is( $second->height, 142, 'height' );
is( $second->width, 43, 'width' );

my $third = $images[2];
is( $third->url, 'linked.gif', 'Got the third image' );
is( $third->tag, 'img', 'input tag' );
is( $third->alt, undef, 'alt' );

my $fourth = $images[3];
is( $fourth->url, 'hacktober.jpg', 'Got the fourth image' );
is( $fourth->tag, 'img', 'input tag' );
is( $fourth->alt, undef, 'alt' );
is( $fourth->attrs->{id}, 'first-hacktober-image', 'id' );
is( $fourth->attrs->{class}, 'my-class-1', 'class' );

my $fifth = $images[4];
is( $fifth->url, 'hacktober.jpg', 'Got the fifth image' );
is( $fifth->tag, 'img', 'input tag' );
is( $fifth->alt, undef, 'alt' );
is( $fifth->attrs->{id}, undef, 'id' );
is( $fifth->attrs->{class}, 'my-class-2 foo', 'class' );

my $sixth = $images[5];
is( $sixth->url, 'hacktober.jpg', 'Got the sixth image' );
is( $sixth->tag, 'img', 'input tag' );
is( $sixth->alt, undef, 'alt' );
is( $sixth->attrs->{id}, undef, 'id' );
is( $sixth->attrs->{class}, 'my-class-3 foo bar', 'class' );