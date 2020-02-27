#!perl -T

use warnings;
use strict;

use Test::More;
use Test::Fatal;
use Test::Warnings ':all';
use Test::Deep;
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

{
    my @images;
    is(
        exception {
            @images = $mech->find_all_images
        },
        undef,
        'find_all_images in the page'
    );

    cmp_deeply(
        [map { $_->url } @images],
        [   qw(
              /Images/bg-gradient.png
              wango.jpg
              bongo.gif
              linked.gif
              hacktober.jpg
              hacktober.jpg
              hacktober.jpg
              http://example.org/abs.tif
              ),
            undef,
            qw(
              images/logo.png
              inner.jpg
              outer.jpg
              ),
        ],
        '... and all ten are in the right order'
    );

    cmp_deeply(
        \@images,
        [ $mech->images ],
        'images() and find_all_images() return the same thing in list context'
    );

    my $images     = $mech->images;
    my $all_images = $mech->find_all_images;
    cmp_deeply(
        $images,
        $all_images,
        'images() and find_all_images() return the same thing in scalar context'
    );
}

# The following data structure describes sets of tests for find_image
# and find_all_images. Each test-case is as follows:
#
# {
#     name => 'Name of the test case',
#     args => [
#         arg_name         => 'value',
#         another_arg_name => 'value,
#     ],
#     expected_single => [ 'WWW::Mechanize::Image method' => 'expected value' ],
#     expected_all    => [
#         # first image
#         [
#             'WWW::Mechanize::Image method'         => 'expected value',
#             'another WWW::Mechanize::Image method' => 'expected value',
#         ],
#         # second image
#         [ 'WWW::Mechanize::Image method' => 'expected value' ]
#     ],
# },
#
# We use Test::Deep to run these tests. The args are key/value pairs
# that will be passed to both find_image() and find_all_images(). This
# allows us to add more complex tests with a combination of different
# arguments easily.
#
# The expected_single and expected_all keys each contain
# a list of methods being called on the resulting WWW::Mechanize::Image
# objects, and the value expected to be returned. For expected_all,
# there is one dedicated list for every image found.
#
# It's possible to use Test::Deep's special functions like re() in the
# value side of the expected data.
#
# This data structure does not cover cases that return no match. See
# further below for those.
#
# To make things easier, these numbered $image variables provide
# shortcuts for all six images in the website. They can be used instead
# of each array reference.

my $image0 = [ url => '/Images/bg-gradient.png', tag => 'css' ]; # this is the body background from the style tag
my $image1 = [ url => 'wango.jpg', alt => re('world of') ];
my $image2 = [ url => 'bongo.gif', tag => 'input', height => 142 ];
my $image3 = [ url => 'linked.gif', tag => 'img' ];
my $image4 = [ url => 'hacktober.jpg', attrs => superhashof( { id => 'first-hacktober-image' } ) ];
my $image5 = [ url => 'hacktober.jpg', attrs => superhashof( { class => re('my-class-2') } ) ];
my $image6 = [ url => 'hacktober.jpg', attrs => superhashof( { class => re('my-class-3') } ) ];
my $image7 = [ url => 'http://example.org/abs.tif', attrs => superhashof( { id => 'absolute' } ) ];
my $image8 = [ url => undef, tag => 'img', attrs => superhashof( { 'data-image' => "hacktober.jpg", id => "no-src-regression-269" } ) ];
my $image9 = [ url => 'images/logo.png', tag => 'css' ];
my $image10 = [ url => 'inner.jpg', tag => 'img' ];
my $image11 = [ url => 'outer.jpg', tag => 'css' ];

my $tests = [
    {
        name => 'CSS',
        args => [
            tag => 'css',
        ],
        expected_single => $image0,
        expected_all => [
            $image0,
            $image9,
            $image11,
        ],
    },
    {
        name => 'alt',
        args => [
            alt => 'The world of the wango',
        ],
        expected_single => $image1,
        expected_all    => [
            $image1,
        ],
    },
    {
        name => 'alt_regex',
        args => [
            alt_regex => qr/world/,
        ],
        expected_single => $image1,
        expected_all    => [
            $image1,
        ],
    },
    {
        name => 'url',
        args => [
            url => 'hacktober.jpg',
        ],
        expected_single => $image4,
        expected_all    => [
            $image4,
            $image5,
            $image6,
        ],
    },
    {
        name => 'url_regex',
        args => [
            url_regex => qr/gif$/,
        ],
        expected_single => $image2,
        expected_all    => [
            $image2,
            $image3,
        ],
    },
    {
        name => 'url_abs',
        args => [
            url_abs => 'http://example.org/abs.tif',
        ],
        expected_single => $image7,
        expected_all    => [
            $image7,
        ],
    },    {
        name => 'url_abs_regex',
        args => [
            url_abs_regex => qr/hacktober/,
        ],
        expected_single => $image4,
        expected_all    => [
            $image4,
            $image5,
            $image6,
        ],
    },
    {
        name => 'tag (img)',
        args => [
            tag => 'img',
        ],
        expected_single => $image1,
        expected_all    => [
            $image1,
            $image3,
            $image4,
            $image5,
            $image6,
            $image7,
            $image8,
            $image10,
        ],
    },
    {
        name => 'tag (input)',
        args => [
            tag => 'input',
        ],
        expected_single => $image2,
        expected_all    => [
            $image2,
        ],
    },
    {
        name => 'tag_regex',
        args => [
            tag_regex => qr/img|input/,
        ],
        expected_single => $image1,
        expected_all    => [
           $image1,
           $image2,
           $image3,
           $image4,
           $image5,
           $image6,
           $image7,
           $image8,
           $image10,
        ],
    },
    {
        name => 'id',
        args => [
            id => 'first-hacktober-image',
        ],
        expected_single => $image4,
        expected_all    => [
            $image4,
        ],
    },
    {
        name => 'id_regex',
        args => [
            id_regex => qr/-/,
        ],
        expected_single => $image4,
        expected_all    => [
            $image4,
            $image8,
        ],
    },
    {
        name => 'class',
        args => [
            class => 'my-class-1',
        ],
        expected_single => $image4,
        expected_all    => [
            $image4,
        ],
    },
    {
        name => 'class_regex',
        args => [
            class_regex => qr/foo/,
        ],
        expected_single => $image5,
        expected_all    => [
            $image5,
            $image6,
        ],
    },
    {
        name => 'class_regex and url',
        args => [
            class_regex => qr/foo/,
            url => 'hacktober.jpg'
        ],
        expected_single => $image5,
        expected_all    => [
            $image5,
            $image6,
        ],
    },
    {
        name => '2nd instance of an image',
        args => [
            url => 'hacktober.jpg',
            n => 2,
        ],
        expected_single => $image5,
    },
    {
      name => 'inline style background image',
      args => [
        url_regex => qr/logo/,
      ],
      expected_single => $image9,
    },
];

foreach my $test ( @{ $tests } ) {
    # verify we find the correct first image with a given set of criteria
    cmp_deeply(
        $mech->find_image( @{ $test->{args} } ),
        all(
            isa('WWW::Mechanize::Image'),
            methods( @{ $test->{expected_single} } ),
        ),
        'find_image: ' . $test->{name}
    );

    if (exists $test->{expected_all}) {
        # verify we find all the correct images with a given set of criteria
        cmp_deeply(
            [ $mech->find_all_images( @{ $test->{args} } ) ],
            [
                map {
                    all(
                        isa('WWW::Mechanize::Image'),
                        methods( @{ $_ } ),
                    )
                }
                @{ $test->{expected_all} }
            ],
            'find_all_images: ' . $test->{name}
        );
    }
}

foreach my $arg (qw/alt url url_abs tag id class/) {
    cmp_deeply(
        [ $mech->find_image( $arg => 'does not exist' ) ],
        [],
        "find_image with $arg that does not exist returns an empty list"
    );

    cmp_deeply(
        [ $mech->find_image( $arg . '_regex' => qr/does not exist/ ) ],
        [],
        "find_image with ${arg}_regex that does not exist returns an empty list"
    );
}

# all of these will find the "wrong" image
{
    my $image;
    like(
        warning {
            $image = $mech->find_image( url => qr/tif$/ )
        },
        qr/is a regex/,
        'find_image warns when it sees an unexpected regex'
    );
    unlike $image->url, qr/tif$/, '... and ignores this argument';
}
{
    my $image;
    like(
        warning {
            $image = $mech->find_image( url_regex => 'tif' )
        },
        qr/is not a regex/,
        'find_image warns when it expects a regex and sees a string'
    );
    unlike $image->url, qr/tif$/, '... and ignores this argument';
}
{
    my $image;
    like(
        warning {
            $image = $mech->find_image( id => q{  absolute  } )
        },
        qr/space-padded and cannot succeed/,
        'find_image warns about space-padding'
    );
    is $image->attrs, undef, '... and ignores this argument';
}

done_testing;
