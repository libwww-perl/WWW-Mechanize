#!perl -Tw

use warnings;
use strict;
use Test::More tests => 8;
use URI::file;

BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)}; # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( 't/field.html' )->as_string;

my $response = $mech->get( $uri );
ok( $response->is_success, "Fetched $uri" );

$mech->field( 'dingo', 'Modified!' );
is( $mech->value( 'dingo' ), 'Modified!', 'dingo got changed' );

$mech->set_visible('bingo', 'bango');
is( $mech->value( 'dingo' ), 'bingo', 'dingo changed' );
is( $mech->value( 'bongo' ), 'bango', 'bongo changed' );

$mech->set_visible( [ radio => 'wongo!' ], 'boingo' );
is( $mech->value( 'wango' ), 'wongo!', 'wango changed' );
is( $mech->value( 'dingo', 2 ), 'boingo', 'dingo changed' );
