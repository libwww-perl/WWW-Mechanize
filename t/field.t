#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 4;
use URI::file;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $t = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $t, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( "t/field.html" )->as_string;

my $response = $t->get( $uri );
ok( $response->is_success, "Fetched $uri" );

$t->field("dingo","Modified!");
my $form = $t->current_form();
is( $form->value( "dingo" ), "Modified!" );
