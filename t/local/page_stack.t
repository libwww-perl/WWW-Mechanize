#!perl

use warnings;
use strict;
use Test::More tests => 11;

use lib 't/local';
use LocalServer;

BEGIN { delete @ENV{ qw( http_proxy HTTP_PROXY ) }; }
BEGIN {
    use_ok( 'WWW::Mechanize' );
}


my $server = LocalServer->spawn;
isa_ok( $server, 'LocalServer' );

my $mech = WWW::Mechanize->new;
isa_ok( $mech, 'WWW::Mechanize', 'Created object' );

is(scalar @{$mech->{page_stack}}, 0, 'Page stack starts empty');
ok( $mech->get($server->url)->is_success, 'Got start page' );
is(scalar @{$mech->{page_stack}}, 0, 'Page stack starts empty');
$mech->_push_page_stack();
is(scalar @{$mech->{page_stack}}, 1, 'Pushed item onto page stack');
$mech->_push_page_stack();
is(scalar @{$mech->{page_stack}}, 2, 'Pushed item onto page stack');
$mech->_pop_page_stack();
is(scalar @{$mech->{page_stack}}, 1, 'Popped item from page stack');
$mech->_pop_page_stack();
is(scalar @{$mech->{page_stack}}, 0, 'Popped item from page stack');
$mech->_pop_page_stack();
is(scalar @{$mech->{page_stack}}, 0, 'Cannot pop beyond end of page stack');
