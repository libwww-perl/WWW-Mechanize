use warnings;
use strict;
use Test::More tests => 14;

use lib 't/lib';
use Test::HTTP::LocalServer;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $server = Test::HTTP::LocalServer->spawn;

my $t = WWW::Mechanize->new();
isa_ok( $t, 'WWW::Mechanize' ) or die;
$t->quiet(1);
$t->get($server->url);
ok( $t->success, "Got a page" ) or die "Can't even get google";
is( ref $t->uri, "", "URI shouldn't be an object" );
is( $t->uri, $server->url, 'Got page' );

my $form_number_1 = $t->form_number(1);
ok( $form_number_1, "Can select the first form");
is( $t->current_form(), $t->{forms}->[0], "Set the form attribute" );

ok( !$t->form(99), "Can't select the 99th form");
is( $t->current_form(), $t->{forms}->[0], "Form is still set to 1" );


my $form_name_f = $t->form_name('f');
ok( $form_name_f, "Can select the form" );
ok( !$t->form('bargle-snark'), "Can't select non-existent form" );

# Make sure form() handles numbers vs. non-numbers correctly
my $form_1 = $t->form(1);
ok( $form_1 );
is( $form_1, $form_number_1 );

my $form_f = $t->form('f');
ok( $form_f );
is( $form_f, $form_name_f );
