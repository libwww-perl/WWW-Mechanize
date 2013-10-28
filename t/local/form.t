#!perl

use warnings;
use strict;
use Test::More tests => 18;

use lib 't/local';
use LocalServer;

BEGIN {
    delete @ENV{ qw( IFS CDPATH ENV BASH_ENV ) };
    use_ok( 'WWW::Mechanize' );
}

my $server = LocalServer->spawn;
isa_ok( $server, 'LocalServer' );

my $mech = WWW::Mechanize->new();
isa_ok( $mech, 'WWW::Mechanize' ) or die;
$mech->quiet(1);
$mech->get($server->url);
ok( $mech->success, 'got a page' ) or die;
is( $mech->uri, $server->url, 'got correct page' );

my $form_number_1 = $mech->form_number(1);
isa_ok( $form_number_1, 'HTML::Form', 'form_number - can select the first form');
is( $mech->current_form(), $mech->{forms}->[0], 'form_number - set the form attribute' );

ok( !$mech->form_number(99), 'form_number - cannot select the 99th form');
is( $mech->current_form(), $mech->{forms}->[0], 'form_number - form is still set to 1' );

my $form_name_f = $mech->form_name('f');
isa_ok( $form_name_f, 'HTML::Form', 'form_name - can select the form' );
ok( !$mech->form_name('bargle-snark'), 'form_name - cannot select non-existent form' );

my $form_id_pounder = $mech->form_id('pounder');
isa_ok( $form_id_pounder, 'HTML::Form', 'form_id - can select the form' );
ok( !$mech->form_id('bargle-snark'), 'form_id - cannot select non-existent form' );

my $form_id_searchbox = $mech->form_action('google-cli');
isa_ok( $form_id_searchbox, 'HTML::Form', 'form_action - can select the form' );
ok( !$mech->form_action('bargle-snark'), 'form_action - cannot select non-existent form' );
my $form;
my $exception = '';
eval {
    $mech->quiet(0);
    local *STDERR;
    open STDERR, '>', \$exception;
    $form = $mech->form_action('formsubmit');
    close STDERR;
};
isa_ok( $form, 'HTML::Form', 'form_action - can select the form');
cmp_ok($exception, 'ne', '', 'form_action - got multiple-matching-forms warning');
like($exception, qr/with action matching/, 'form_action - got correct multiple-matching-forms warning');
$mech->quiet(1);
