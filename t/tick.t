#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use URI::file;

use_ok( 'WWW::Mechanize' );

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, "WWW::Mechanize" );

my $uri = URI::file->new_abs( "t/tick.html" )->as_string;
$mech->get( $uri );
ok( $mech->success, $uri );

$mech->form_number( 1 );
$mech->tick("foo","hello");
$mech->tick("foo","bye");
$mech->untick("foo","hello");

my @forms = $mech->forms();
my $form = $forms[0];

my $reqstring = $form->click->as_string;

my $wanted = <<'EOT';
POST http://localhost/
Content-Length: 21
Content-Type: application/x-www-form-urlencoded

foo=bye&submit=Submit
EOT

is( $reqstring, $wanted, "Proper posting" );

