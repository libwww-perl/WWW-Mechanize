#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 4;
use File::Spec;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $t = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $t, 'WWW::Mechanize' );

my $file = File::Spec->rel2abs( "t/field.html" ) ;
my $response = $t->get( "file:///$file" );
ok( $response->is_success, "Fetched the file" );

$t->field("dingo","Modified!");
my $form = $t->current_form();
is( $form->value( "dingo" ), "Modified!" );
