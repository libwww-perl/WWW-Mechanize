use warnings;
use strict;
use Test::More;

use lib 't/local';
use LocalServer ();

BEGIN {
    delete @ENV{qw( IFS CDPATH ENV BASH_ENV )};
    use_ok('WWW::Mechanize');
}

my $server = LocalServer->spawn;
isa_ok( $server, 'LocalServer' );

my @warnings;
my $mech = WWW::Mechanize->new( onwarn => sub { push @warnings, @_ } );
isa_ok( $mech, 'WWW::Mechanize' ) or die;
$mech->quiet(1);
$mech->get( $server->url );
ok( $mech->success, 'got a page' ) or die;
is( $mech->uri, $server->url, 'got correct page' );

my ( $form, $number ) = $mech->form_number(1);
isa_ok( $form, 'HTML::Form',
    'form_number - can select the first form in list context call' );
is( $number, 1, 'form_number - form number is correct' );

my $form_number_1 = $mech->form_number(1);
isa_ok( $form_number_1, 'HTML::Form',
    'form_number - can select the first form' );
is(
    $mech->current_form(),
    $mech->{forms}->[0],
    'form_number - set the form attribute'
);

ok( !$mech->form_number(99), 'form_number - cannot select the 99th form' );
is(
    $mech->current_form(),
    $mech->{forms}->[0],
    'form_number - form is still set to 1'
);

my $form_name_f = $mech->form_name('f');
isa_ok( $form_name_f, 'HTML::Form', 'form_name - can select the form' );
ok( !$mech->form_name('bargle-snark'),
    'form_name - cannot select non-existent form' );

$form_name_f = $mech->form_name('mf');
isa_ok( $form_name_f, 'HTML::Form', 'form_name - can select the form' );

$form_name_f = $mech->form_name( 'mf', { n => 1 } );
isa_ok( $form_name_f, 'HTML::Form',
    'form_name - can select the 1st multiform' );

$form_name_f = $mech->form_name( 'mf', { n => 2 } );
isa_ok( $form_name_f, 'HTML::Form',
    'form_name - can select the 2nd multiform' );
ok( !$mech->form_name( 'mf', { n => 3 } ),
    'form_name - cannot select non-existent multiform' );

my $form_id_pounder = $mech->form_id('pounder');

isa_ok( $form_id_pounder, 'HTML::Form', 'form_id - can select the form' );
ok( !$mech->form_id('bargle-snark'),
    'form_id - cannot select non-existent multiform' );

$form_id_pounder = $mech->form_id('multiform');
isa_ok( $form_id_pounder, 'HTML::Form', 'form_id - can select the multiform' );

$form_id_pounder = $mech->form_id( 'multiform', { n => 1 } );
isa_ok( $form_id_pounder, 'HTML::Form',
    'form_id - can select the 1st multiform' );

$form_id_pounder = $mech->form_id( 'multiform', { n => 2 } );
isa_ok( $form_id_pounder, 'HTML::Form',
    'form_id - can select the 2nd multiform' );
ok(
    !$mech->form_id( 'multiform', { n => 3 } ),
    'form_id - cannot select non-existent multiform'
);

my $form_with = $mech->form_with( class => 'test', id => undef );
isa_ok( $form_with, 'HTML::Form',
    'form_with - can select the form without id' );
is( $mech->current_form, $form_number_1,
    'form_with - form without id is now the current form' );

my $form_number_2 = $mech->form_number(2);
$form_with =
  $mech->form_with( class => 'test', foo => '', bar => undef, { n => 2 } );
is( $form_with, $form_number_2, 'Can select nth form with ambiguous criteria' );

is( scalar @warnings, 0, 'no warnings so far' );
$mech->quiet(0);
$form_with = $mech->form_with( class => 'test', foo => '', bar => undef );
is( $form_with, $form_number_1,
    'form_with - can select form with ambiguous criteria' );
is( scalar @warnings, 1, 'form_with - got one warning' );
is(
    "@warnings",
    'There are 2 forms with no bar and class "test"'
      . ' and empty foo.  The first one was used.',
    'Got expected warning'
);
$mech->quiet(1);

my $form_id_searchbox = $mech->form_action('google-cli');
isa_ok( $form_id_searchbox, 'HTML::Form', 'form_action - can select the form' );
ok( !$mech->form_action('bargle-snark'),
    'form_action - cannot select non-existent form' );

$mech->quiet(0);
my $form_action = $mech->form_action('formsubmit');
isa_ok( $form_action, 'HTML::Form', 'form_action - can select the form' );
is( scalar @warnings, 2, 'form_action - got one warning' );
like(
    $warnings[-1],
    qr/with action matching/,
    'form_action - got correct multiple-matching-forms warning'
);
$mech->quiet(1);

done_testing;
