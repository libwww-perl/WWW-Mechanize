use warnings;
use strict;
use Test::More tests => 28;

use lib 't/local';
use LocalServer;

BEGIN {
    delete @ENV{ qw( IFS CDPATH ENV BASH_ENV ) };
    use_ok( 'WWW::Mechanize' );
}

my $server = LocalServer->spawn;
isa_ok( $server, 'LocalServer' );

my @warnings;
my $mech = WWW::Mechanize->new( onwarn => sub { push @warnings, @_ } );
isa_ok( $mech, 'WWW::Mechanize' ) or die;
$mech->quiet(1);
$mech->get($server->url);
ok( $mech->success, 'Got a page' ) or die;
is( $mech->uri, $server->url, 'Got page' );

my $form_number_1 = $mech->form_number(1);
isa_ok( $form_number_1, 'HTML::Form', 'Can select the first form');
is( $mech->current_form(), $mech->{forms}->[0], 'Set the form attribute' );

ok( !$mech->form_number(99), 'cannot select the 99th form');
is( $mech->current_form(), $mech->{forms}->[0], 'Form is still set to 1' );

my $form_name_f = $mech->form_name('f');
isa_ok( $form_name_f, 'HTML::Form', 'Can select the form' );
ok( !$mech->form_name('bargle-snark'), 'cannot select non-existent form' );

$form_name_f = $mech->form_name('mf');
isa_ok( $form_name_f, 'HTML::Form', 'Can select the form' );

$form_name_f = $mech->form_name('mf', 1);
isa_ok( $form_name_f, 'HTML::Form', 'Can select the 1st multiform' );

$form_name_f = $mech->form_name('mf', 2);
isa_ok( $form_name_f, 'HTML::Form', 'Can select the 2nd multiform' );
ok( !$mech->form_name('mf', 3), 'cannot select non-existent multiform' );

my $form_id_pounder = $mech->form_id('pounder');
isa_ok( $form_id_pounder, 'HTML::Form', 'Can select the form' );
ok( !$mech->form_id('bargle-snark'), 'cannot select non-existent multiform' );

$form_id_pounder = $mech->form_id('multiform');
isa_ok( $form_id_pounder, 'HTML::Form', 'Can select the multiform' );

$form_id_pounder = $mech->form_id('multiform', 1);
isa_ok( $form_id_pounder, 'HTML::Form', 'Can select the 1st multiform' );

$form_id_pounder = $mech->form_id('multiform' ,2);
isa_ok( $form_id_pounder, 'HTML::Form', 'Can select the 2nd multiform' );
ok( !$mech->form_id('multiform', 3), 'cannot select non-existent multiform' );

my $form_with = $mech->form_with( class => 'test', id => undef );
isa_ok( $form_with, 'HTML::Form', 'Can select the form without id' );
is( $mech->current_form, $form_number_1,
    'Form without id is now the current form' );

my $form_number_2 = $mech->form_number(2);
$form_with = $mech->form_with( class => 'test', foo => '', bar => undef, nth => 2 );
is( $form_with, $form_number_2, 'Can select nth form with ambiguous criteria' );

is( scalar @warnings, 0, 'no warnings so far' );
$mech->quiet(0);
$form_with = $mech->form_with( class => 'test', foo => '', bar => undef );
is( $form_with, $form_number_1, 'Can select form with ambiguous criteria' );
is( scalar @warnings, 1, 'Got one warning' );
is(
    "@warnings",
    'There are 2 forms with no bar and class "test"'
      . ' and empty foo.  The first one was used.',
    'Got expected warning'
);
