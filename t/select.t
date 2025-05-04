#!perl

use warnings;
use strict;
use Test::More;
use Test::Warnings qw(warning :no_end_test);
use URI::file      ();

BEGIN {
    use_ok('WWW::Mechanize');
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri      = URI::file->new_abs('t/select.html')->as_string;
my $response = $mech->get($uri);
ok( $response->is_success, "Fetched $uri" );

my (
    $sendsingle, @sendmulti, %sendsingle, %sendmulti,
    $rv, $return, @return, @singlereturn, $form
);

# possible values are: aaa, bbb, ccc, ddd
$sendsingle   = 'aaa';
@sendmulti    = qw(bbb ccc);
@singlereturn = ( $sendmulti[0] );
%sendsingle   = ( n => 1 );
%sendmulti    = ( n => [ 2, 3 ] );

ok( $mech->form_number(1), 'set form to number 1' );
$form = $mech->current_form();

# Multi-select

# pass multiple values to a multi select
$form->param( 'multilist', undef );
$mech->select( 'multilist', \@sendmulti );
@return = $form->param('multilist');
is_deeply(
    \@return, \@sendmulti,
    'multi->multi value is ' . join( ' ', @return )
);

$form->param( 'multilist', undef );
$mech->select( 'multilist', \%sendmulti );
@return = $form->param('multilist');
is_deeply(
    \@return, \@sendmulti,
    'multi->multi value is ' . join( ' ', @return )
);

# pass a single value to a multi select
$form->param( 'multilist', undef );
$mech->select( 'multilist', $sendsingle );
$return = $form->param('multilist');
is( $return, $sendsingle, "single->multi value is '$return'" );

$form->param( 'multilist', undef );
$mech->select( 'multilist', \%sendsingle );
$return = $form->param('multilist');
is( $return, $sendsingle, "single->multi value is '$return'" );

# Single select

# pass multiple values to a single select (only the _first_ should be set)
$form->param( 'singlelist', undef );
$mech->select( 'singlelist', \@sendmulti );
@return = $form->param('singlelist');
is_deeply(
    \@return, \@singlereturn,
    'multi->single value is ' . join( ' ', @return )
);

$form->param( 'singlelist', undef );
$mech->select( 'singlelist', \%sendmulti );
@return = $form->param('singlelist');
is_deeply(
    \@return, \@singlereturn,
    'multi->single value is ' . join( ' ', @return )
);

# pass a single value to a single select
$form->param( 'singlelist', undef );
$rv     = $mech->select( 'singlelist', $sendsingle );
$return = $form->param('singlelist');
is( $return, $sendsingle, "single->single value is '$return'" );

$form->param( 'singlelist', undef );
$rv     = $mech->select( 'singlelist', \%sendsingle );
$return = $form->param('singlelist');
is( $return, $sendsingle, "single->single value is '$return'" );

# test return value from $mech->select
is( $rv, 1, 'return 1 after successful select' );

like warning { $rv = $mech->select( 'missing_list', 1 ) }, qr/not found/,
    'warning when field is not found';
is( $rv, undef, 'return undef after failed select' );

# test setting a number
$mech->select( 'exists_twice', 'two',  1 );
$mech->select( 'exists_twice', 'four', 2 );
@return = $form->param('exists_twice');
is_deeply(
    \@return, [ 'two', 'four' ],
    'select exists twice, set both and values are ' . join( ' ', @return )
);

$mech->select( 'exists_twice', 'one', 1 );
$mech->select( 'exists_twice', 'one', 2 );
@return = $form->param('exists_twice');
is_deeply(
    \@return, [ 'one', 'one' ],
    'select exists twice, set to double values and they are '
        . join( ' ', @return )
);

done_testing;
