#!perl -T

use warnings;
use strict;
use Test::More tests => 8;
use URI::file;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( "t/field.html" )->as_string;

my $response = $mech->get( $uri );
ok( $response->is_success, "Fetched $uri" );

$mech->field("dingo","Modified!");
my $form = $mech->current_form();
is( $form->value( "dingo" ), "Modified!" );

$mech->set_visible("bingo", "bango");
$form = $mech->current_form();
is( $form->value( "dingo" ), "bingo" );
is( $form->value( "bongo" ), "bango" );

$mech->set_visible( [ radio => "wongo!" ], "boingo" );
$form = $mech->current_form();
is( $form->value( "wango" ), "wongo!" );
is( $form->find_input( "dingo", undef, 2 )->value, "boingo" );
