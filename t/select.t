#!perl -T

use warnings;
use strict;
use Test::More tests => 14;
use URI::file;

BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};  # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( "t/select.html" )->as_string;
my $response = $mech->get( $uri );
ok( $response->is_success, "Fetched $uri" );

my ($sendsingle, @sendmulti, %sendsingle, %sendmulti,
    $rv, $return, @return, @singlereturn, $form);
# possible values are: aaa, bbb, ccc, ddd
$sendsingle = 'aaa';
@sendmulti = qw(bbb ccc);
@singlereturn = ($sendmulti[0]);
%sendsingle = (n => 1);
%sendmulti = (n => [2, 3]);

ok($mech->form_number(1), "set form to number 1");
$form = $mech->current_form();


# Multi-select

# pass multiple values to a multi select
$mech->select("multilist", \@sendmulti);
@return = $form->param("multilist");
is_deeply(\@return, \@sendmulti, "multi->multi value is " . join(' ', @return));

$mech->select("multilist", \%sendmulti);
@return = $form->param("multilist");
is_deeply(\@return, \@sendmulti, "multi->multi value is " . join(' ', @return));

# pass a single value to a multi select
$mech->select("multilist", $sendsingle);
$return = $form->param("multilist");
is($return, $sendsingle, "single->multi value is '$return'");

$mech->select("multilist", \%sendsingle);
$return = $form->param("multilist");
is($return, $sendsingle, "single->multi value is '$return'");


# Single select

# pass multiple values to a single select (only the _first_ should be set)
$mech->select("singlelist", \@sendmulti);
@return = $form->param("singlelist");
is_deeply(\@return, \@singlereturn, "multi->single value is " . join(' ', @return));

$mech->select("singlelist", \%sendmulti);
@return = $form->param("singlelist");
is_deeply(\@return, \@singlereturn, "multi->single value is " . join(' ', @return));


# pass a single value to a single select
$rv = $mech->select("singlelist", $sendsingle);
$return = $form->param("singlelist");
is($return, $sendsingle, "single->single value is '$return'");

$rv = $mech->select("singlelist", \%sendsingle);
$return = $form->param("singlelist");
is($return, $sendsingle, "single->single value is '$return'");

# test return value from $mech->select
is($rv, 1, 'return 1 after successful select');

EAT_THE_WARNING: { # Mech complains about the non-existent field
    local $SIG{__WARN__} = sub {};
    $rv = $mech->select('missing_list', 1);
}
is($rv, undef, 'return undef after failed select');
