use warnings;
use strict;
use Test::More tests => 6;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $t = WWW::Mechanize->new();
isa_ok( $t, 'WWW::Mechanize' );
$t->get("http://www.google.com");
ok($t->form(1), "Can select the first form");
is($t->{form}, $t->{forms}->[0], "Set the form attribute");
ok(! $t->form(99), "Can't select the 99th form");
is($t->{form}, $t->{forms}->[0], "Form is still set to 1");
