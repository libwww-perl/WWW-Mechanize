use warnings;
use strict;
use Test::More tests => 9;

use lib 't/lib';
use Test::HTTP::LocalServer;
my $server = Test::HTTP::LocalServer->spawn;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $t = WWW::Mechanize->new;
isa_ok( $t, 'WWW::Mechanize', 'Created object' );

ok( $t->get($server->url)->is_success, "Got Google" );
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
