#!perl -T

use warnings;
use strict;

use Test::More tests => 11;
use URI::file ();

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( 't/find_inputs.html' )->as_string;

$mech->get( $uri );
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

FIRST_FORM: {
    my @inputs = $mech->find_all_inputs();
    is( scalar @inputs, 3, 'Exactly three inputs' );

    my @submits = $mech->find_all_submits();
    is( scalar @submits, 2, 'Exactly two submits' );
}

SECOND_FORM: {
    $mech->form_number(2);
    my @inputs = $mech->find_all_inputs();
    is( scalar @inputs, 4, 'Exactly four inputs' );

    my @submits = $mech->find_all_submits();
    is( scalar @submits, 1, 'Exactly one submit' );
}

THIRD_FORM: {
    $mech->form_number(3);
    my @inputs = $mech->find_all_inputs();
    is( scalar @inputs, 5, 'Exactly five inputs' );

    my @relatives = $mech->find_all_inputs( name_regex => qr/^Your/ );
    is( scalar @relatives, 4, 'Found four relatives' );

    my @sisters = $mech->find_all_inputs( name => 'YourSister' );
    is( scalar @sisters, 2, 'Found two sisters' );

    my @submit_sisters = $mech->find_all_inputs( name => 'YourSister' );
    is( scalar @submit_sisters, 2, 'But no sisters are submits' );
}
