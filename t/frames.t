#!perl

use warnings;
use strict;
use Test::More tests => 7;
use URI::file ();

BEGIN {
    use_ok('WWW::Mechanize');
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs('t/frames.html')->as_string;

$mech->get($uri);
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

my $link = $mech->find_link();
isa_ok( $link, 'WWW::Mechanize::Link' );

my @links = $mech->find_all_links();
is( scalar @links, 2, 'Only two links' );

is_deeply(
    [ @{ $links[0] }[ 0 .. 3 ] ],
    [ 'find_link.html', undef, 'top', 'frame' ], 'First frame OK'
);

is_deeply(
    [ @{ $links[1] }[ 0 .. 3 ] ],
    [ 'google.html', undef, 'bottom', 'frame' ], 'Second frame OK'
);
