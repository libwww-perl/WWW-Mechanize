#!perl -Tw

use warnings;
use strict;
use Test::More tests => 8;
use URI::file;

BEGIN {
	delete @ENV{qw(PATH)}; # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( "t/field.html" )->as_string;

my $response = $mech->get( $uri );
ok( $response->is_success, "Fetched $uri" );

$mech->field( "dingo", "Modified!" );
is( $mech->value( "dingo" ), "Modified!" );

$mech->set_visible("bingo", "bango");
is( $mech->value( "dingo" ), "bingo" );
is( $mech->value( "bongo" ), "bango" );

$mech->set_visible( [ radio => "wongo!" ], "boingo" );
is( $mech->value( "wango" ), "wongo!" );
is( $mech->value( "dingo", 2 ), "boingo" );
