use warnings;
use strict;
use Test::More tests=>15;

use constant START => 'http://www.google.com/intl/en/';

use_ok( 'WWW::Mechanize' );

my $mech = WWW::Mechanize->new();
isa_ok( $mech, 'WWW::Mechanize' ) or die;
$mech->quiet(1);
$mech->get(START);
ok( $mech->success, "Got a page" ) or die "Can't even get google";
is( $mech->uri, START, 'Got Google' );
like( $mech->title, qr/Google/ );

my $form_number_1 = $mech->form_number(1);
isa_ok( $form_number_1, 'HTML::Form', "Can select the first form");
is( $mech->current_form(), $mech->{forms}->[0], "Set the form attribute" );

ok( !$mech->form(99), "Can't select the 99th form");
is( $mech->current_form(), $mech->{forms}->[0], "Form is still set to 1" );


my $form_name_f = $mech->form_name('f');
isa_ok( $form_name_f, 'HTML::Form', "Can select the form" );
ok( !$mech->form('bargle-snark'), "Can't select non-existent form" );

# Make sure form() handles numbers vs. non-numbers correctly
my $form_1 = $mech->form(1);
isa_ok( $form_1, 'HTML::Form' );
is( $form_1, $form_number_1 );

my $form_f = $mech->form('f');
isa_ok( $form_f, 'HTML::Form' );
is( $form_f, $form_name_f );
