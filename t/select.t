#!perl -T

use warnings;
use strict;
use Test::More tests => 7;
use URI::file;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( "t/select.html" )->as_string;
my $response = $mech->get( $uri );
ok( $response->is_success, "Fetched $uri" );

my (@send, @return, $form);
push @send, "bbb";
push @send, "ccc";

ok($mech->form_number(1), "set form to number 1");
$form = $mech->current_form();

# multi-select list
$mech->select("multilist",\@send);
@return = $form->param("multilist");
cmp_ok( @return, 'eq', @send, "value is " . join(' ', @send));

# single select list

# push an array of values
# only the last should be set
$mech->select("singlelist",\@send);
@return = $form->param("singlelist");
push my @singlereturn, pop(@send);
cmp_ok( @return, 'eq', @singlereturn, "value is " . pop(@send));

# push a single value into a single select
$mech->select("singlelist","aaa");
is( $form->param("singlelist"), "aaa", "value is 'aaa'");
