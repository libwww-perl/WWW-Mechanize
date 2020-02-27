#!perl -T

use warnings;
use strict;

use Test::More tests => 47;
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
is( scalar @images, 12, 'Exactly twelve images' );

my $first = $images[0];
is( $first->url, '/Images/bg-gradient.png', 'Got the background style image' );
is( $first->tag, 'css', 'css tag' );
is( $first->alt, undef, 'alt' );

my $second = $images[1];
is( $second->tag, 'img', 'img tag' );
is( $second->url, 'wango.jpg', 'URL matches' );
is( $second->alt, 'The world of the wango', 'alt matches' );

my $third = $images[2];
is( $third->tag, 'input', 'input tag' );
is( $third->url, 'bongo.gif', 'URL matches' );
is( $third->alt, undef, 'alt matches' );
is( $third->height, 142, 'height' );
is( $third->width, 43, 'width' );

my $fourth = $images[3];
is( $fourth->url, 'linked.gif', 'Got the fourth image' );
is( $fourth->tag, 'img', 'input tag' );
is( $fourth->alt, undef, 'alt' );

my $fifth = $images[4];
is( $fifth->url, 'hacktober.jpg', 'Got the fifth image' );
is( $fifth->tag, 'img', 'input tag' );
is( $fifth->alt, undef, 'alt' );
is( $fifth->attrs->{id}, 'first-hacktober-image', 'id' );
is( $fifth->attrs->{class}, 'my-class-1', 'class' );

my $sixth = $images[5];
is( $sixth->url, 'hacktober.jpg', 'Got the sixth image' );
is( $sixth->tag, 'img', 'input tag' );
is( $sixth->alt, undef, 'alt' );
is( $sixth->attrs->{id}, undef, 'id' );
is( $sixth->attrs->{class}, 'my-class-2 foo', 'class' );

my $seventh = $images[6];
is( $seventh->url, 'hacktober.jpg', 'Got the seventh image' );
is( $seventh->tag, 'img', 'input tag' );
is( $seventh->alt, undef, 'alt' );
is( $seventh->attrs->{id}, undef, 'id' );
is( $seventh->attrs->{class}, 'my-class-3 foo bar', 'class' );

# regression github #269
my $eighth = $images[8];
is( $eighth->attrs->{id}, 'no-src-regression-269', 'Got the eighth image');
is( $eighth->url, undef, 'it has no URL');
is( $eighth->attrs->{'data-image'}, 'hacktober.jpg', 'it has an extra attribute');

my $ninth = $images[9];
is( $ninth->url, 'images/logo.png', 'Got the fifth image' );
is( $ninth->tag, 'css', 'css tag' );
is( $ninth->alt, undef, 'alt' );

# find image in css
$uri = URI::file->new_abs( 't/image-parse.css' )->as_string;

$mech->get( $uri );
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

eval { @images = $mech->find_all_images(); };
is($@,'','survived eval');
is( scalar @images, 2, 'Exactly two images' );

my $css_first = $images[0];
is( $css_first->url, '/Images/bg-gradient.png', 'Got the first image' );
is( $css_first->tag, 'css', 'css tag' );
is( $css_first->alt, undef, 'alt' );

my $css_second = $images[1];
is( $css_second->url, 'images/logo.png', 'Got the second image' );
is( $css_second->tag, 'css', 'css tag' );