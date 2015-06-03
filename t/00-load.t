#!perl -T

use warnings;
use strict;
use lib 't';
use Test::More tests => 2;
use Tools;

use_ok( 'WWW::Mechanize' );
use_ok( 'WWW::Mechanize::Link' );

diag( "Testing WWW::Mechanize $WWW::Mechanize::VERSION, with LWP $LWP::VERSION, Perl $], $^X" );
if ( $canTMC ) {
    diag( "Test::Memory::Cycle $Test::Memory::Cycle::VERSION is installed." );
}
else {
    diag( 'Test::Memory::Cycle is not installed.' );
}
