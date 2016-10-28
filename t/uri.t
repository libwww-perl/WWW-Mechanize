use strict;
use warnings;

use Test::More;
use WWW::Mechanize ();

my $mech = WWW::Mechanize->new;
is( $mech->uri, undef, 'undef uri() with a pristine object' );

done_testing();
