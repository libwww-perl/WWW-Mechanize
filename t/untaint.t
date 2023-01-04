use strict;
use warnings;
use URI::file ();

use Test::More;
use Test::Warnings;

plan( tests => 2 ); # the use_ok and then the warning check
$ENV{test} = 14;
use_ok( 'WWW::Mechanize' );
my $uri = URI::file->new_abs( 't/find_link_id.html' )->as_string;
WWW::Mechanize->new->get($uri);
