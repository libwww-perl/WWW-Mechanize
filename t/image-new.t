#!perl -T

use warnings;
use strict;

use Test::More tests => 15;

BEGIN {
    use_ok('WWW::Mechanize::Image');
}

# test new style API
my $img = WWW::Mechanize::Image->new(
    {
        url    => 'url.html',
        base   => 'http://base.example.com/',
        name   => 'name',
        alt    => 'alt',
        tag    => 'a',
        height => 2112,
        width  => 5150,
        attrs  => { id => 'id', class => 'foo bar' },
    }
);

is( $img->url,            'url.html',                  'url() works' );
is( $img->base,           'http://base.example.com/',  'base() works' );
is( $img->name,           'name',                      'name() works' );
is( $img->alt,            'alt',                       'alt() works' );
is( $img->tag,            'a',                         'tag() works' );
is( $img->height,         2112,                        'height works' );
is( $img->width,          5150,                        'width works' );
is( $img->attrs->{id},    'id',                        'attrs/id works' );
is( $img->attrs->{class}, 'foo bar',                   'attrs/class works' );
is( $img->url_abs, 'http://base.example.com/url.html', 'url_abs works' );
isa_ok( $img->URI, 'URI::URL', 'Returns an object' );

my $img_no_src = WWW::Mechanize::Image->new(
    {
        url    => undef,
        base   => 'http://base.example.com/',
        tag    => 'img',
        height => 123,
        width  => 321,
    }
);

isa_ok( $img_no_src, 'WWW::Mechanize::Image' );
is( $img_no_src->url, undef, 'url() without url is undef' );
isa_ok( $img_no_src->URI, 'URI::URL', 'Returns an object' );
