#!perl -T

use warnings;
use strict;

use Test::More tests => 5;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new;
isa_ok( $mech, 'WWW::Mechanize', 'Created object' );
$mech->agent_alias('Linux Mozilla');

$mech->get( 'http://www.computers4sure.com/' );
ok( $mech->content =~ /Support/, 'Found a likely word.' );

$mech->get( 'http://www.computers4sure.com/Product.asp?ProductID=5507338&iid=1049' );
ok( $mech->content =~ /FreeAgent/, 'Found a likely word.' );
print $mech->content;

SKIP: {
    eval "use Test::Memory::Cycle";
    skip "Test::Memory::Cycle not installed", 1 if $@;

    memory_cycle_ok( $mech, "No memory cycles found" );
}

