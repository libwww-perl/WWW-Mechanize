#!perl -T

use warnings;
use strict;
use Test::More;
eval 'use Test::Taint';
plan skip_all => 'Test::Taint required for checking taintedness' if $@;
plan tests=>5;

BEGIN { delete @ENV{ qw( http_proxy HTTP_PROXY ) }; }
BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( autocheck => 1 );
isa_ok( $mech, 'WWW::Mechanize', 'Created object' );

$mech->get( 'file:t/google.html' );

# Make sure taint checking is on correctly
my @keys = keys %ENV;
tainted_ok( $ENV{ $keys[0] }, 'ENV taints OK' );

is( $mech->title, 'Google', 'Correct title' );
untainted_ok( $mech->title, 'Title should not be tainted' );

TODO: {
    local $TODO = q{I don't know why this is magically no longer tainted.};
    tainted_ok( $mech->content, 'But content should' );
}
