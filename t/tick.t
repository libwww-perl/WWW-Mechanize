#!/usr/bin/perl -w

use strict;
use Test::More;

# TODO: Run this locally, and just look at the request
plan skip_all => "Skipping live tests" if -f "t/SKIPLIVE";
plan tests => 6;

use_ok( 'WWW::Mechanize' );

my $mech = WWW::Mechanize->new();
isa_ok( $mech, "WWW::Mechanize" );
$mech->get("http://2shortplanks.com/ticky/checkbox.html");
ok( $mech->success, "Got the page OK" );

$mech->form_number( 1 );
$mech->tick("foo","hello");
$mech->tick("foo","bye");
$mech->untick("foo","hello");

$mech->submit;
ok( $mech->success, "Posted OK" );

like($mech->content(), "/foo=bye/");
unlike($mech->content(), "/foo=hello/");
