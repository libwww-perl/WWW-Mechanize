use warnings;
use strict;
use Test::More tests => 8;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $t = WWW::Mechanize->new;
isa_ok( $t, 'WWW::Mechanize', 'Created object' );

$t->get("http://www.google.com");
is(scalar @{$t->{page_stack}}, 0, "Page stack starts empty");
$t->push_page_stack();
is(scalar @{$t->{page_stack}}, 1, "Pushed item onto page stack");
$t->push_page_stack();
is(scalar @{$t->{page_stack}}, 2, "Pushed item onto page stack");
$t->pop_page_stack();
is(scalar @{$t->{page_stack}}, 1, "Popped item from page stack");
$t->pop_page_stack();
is(scalar @{$t->{page_stack}}, 0, "Popped item from page stack");
$t->pop_page_stack();
is(scalar @{$t->{page_stack}}, 0, "Can't pop beyond end of page stack");
