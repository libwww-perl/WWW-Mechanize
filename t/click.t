use warnings;
use strict;
use Test::More tests => 3;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $t = WWW::Mechanize->new();
$t->get("http://www.google.com");
$t->field(q => "foo");
ok($t->click("btnG"), "Can click 'btnG' ('Google Search' button)");
like($t->{content}, qr/foo\s?fighters/i, "Found 'Foo Fighters'");
