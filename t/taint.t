#!perl -T

use warnings;
use strict;
use Test::More;

BEGIN {
    eval 'use Test::Taint';
    plan skip_all => 'Test::Taint required for checking taintedness' if $@;
    plan tests=>6;
}

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( autocheck => 1 );
isa_ok( $mech, 'WWW::Mechanize', 'Created object' );

$mech->get( 'file:t/google.html' );

# Make sure taint checking is on correctly
tainted_ok( $^X, 'Interpreter Variable taints OK' );

is( $mech->title, 'Google', 'Correct title' );
untainted_ok( $mech->title, 'Title should not be tainted' );

tainted_ok( $mech->content, 'But content should' );
