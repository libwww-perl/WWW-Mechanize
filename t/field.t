#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 4;
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
