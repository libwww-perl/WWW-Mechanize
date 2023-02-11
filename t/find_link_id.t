#!perl -T

use warnings;
use strict;
use Test::More 'no_plan';
use URI::file ();

BEGIN {
    use_ok('WWW::Mechanize');
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs('t/find_link_id.html')->as_string;

$mech->get($uri);
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

FIND_BY_ID: {
    my $x = $mech->find_link( id => 'signature' );
    isa_ok( $x, 'WWW::Mechanize::Link' );
    is( $x->url, 'signature.html', 'found link with given ID' );
}

FIND_BY_CLASS: {
    my $x = $mech->find_link( tag => 'iframe', class => 'smart_iframe' );
    isa_ok( $x, 'WWW::Mechanize::Link' );
    is(
        $x->url, 'http://boo.xyz.com/boo_app',
        'found link within "iframe" with given class'
    );
}

FIND_ID_BY_REGEX: {
    my $x = $mech->find_link( id_regex => qr/^sig/ );
    isa_ok( $x, 'WWW::Mechanize::Link' );
    is( $x->url, 'signature.html', 'found link with ID matching a regex' );
}

FIND_CLASS_BY_REGEX: {
    my $x = $mech->find_link( tag => 'iframe', class_regex => qr/IFRAME$/i );
    isa_ok( $x, 'WWW::Mechanize::Link' );
    is(
        $x->url, 'http://boo.xyz.com/boo_app',
        'found link with class matching a regex'
    );
}
