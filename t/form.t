use warnings;
use strict;
use Test::More tests => 8;

use constant START => 'http://www.google.com/intl/en/';

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $t = WWW::Mechanize->new();
isa_ok( $t, 'WWW::Mechanize' );
my $response = $t->get(START);
ok( $response->is_success, "Got a page" ) or die "Can't even get google";
is( $t->uri, START, 'Got Google' );
ok($t->form(1), "Can select the first form");
is($t->{form}, $t->{forms}->[0], "Set the form attribute");
ok(! $t->form(99), "Can't select the 99th form");
is($t->{form}, $t->{forms}->[0], "Form is still set to 1");
