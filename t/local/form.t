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

my $mech = WWW::Mechanize->new();
isa_ok( $mech, 'WWW::Mechanize' ) or die;
$mech->quiet(1);
$mech->get($server->url);
ok( $mech->success, "Got a page" ) or die "Can't even get google";
is( $mech->uri, $server->url, 'Got page' );

my $form_number_1 = $mech->form_number(1);
isa_ok( $form_number_1, "HTML::Form", "Can select the first form");
is( $mech->current_form(), $mech->{forms}->[0], "Set the form attribute" );

ok( !$mech->form_number(99), "Can't select the 99th form");
is( $mech->current_form(), $mech->{forms}->[0], "Form is still set to 1" );

my $form_name_f = $mech->form_name('f');
isa_ok( $form_name_f, "HTML::Form", "Can select the form" );
ok( !$mech->form_name('bargle-snark'), "Can't select non-existent form" );
