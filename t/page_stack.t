use warnings;
use strict;
use Test::More;

# XXX There's no reason this one couldn't run off the local server.
plan skip_all => "Skipping live tests" if -f "t/SKIPLIVE";
plan tests => 9;

use_ok( 'WWW::Mechanize' );

my $t = WWW::Mechanize->new;
isa_ok( $t, 'WWW::Mechanize' ) or die;

$t->get("http://www.google.com/intl/en/");
ok( $t->success, "Got Google" );
is(scalar @{$t->{page_stack}}, 0, "Page stack starts empty");
$t->_push_page_stack();
is(scalar @{$t->{page_stack}}, 1, "Pushed item onto page stack");
$t->_push_page_stack();
is(scalar @{$t->{page_stack}}, 2, "Pushed item onto page stack");
$t->_pop_page_stack();
is(scalar @{$t->{page_stack}}, 1, "Popped item from page stack");
$t->_pop_page_stack();
is(scalar @{$t->{page_stack}}, 0, "Popped item from page stack");
$t->_pop_page_stack();
is(scalar @{$t->{page_stack}}, 0, "Can't pop beyond end of page stack");
