#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 5;
use URI::file;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $t = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $t, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( "t/area_link.html" );
$t->get( $uri );
ok( $t->success, "Fetched $uri" ) or die "Can't get test page";

AREA_CHECKS: {
    my @wanted_links = (
	[ "http://www.msnbc.com/area", undef, undef, "area" ],
	[ "http://www.cnn.com/area", undef, undef, "area" ],
	[ "http://www.cpan.org/area", undef, undef, "area" ],
	[ "http://www.slashdot.org", undef, undef, "area" ],
    );
    my @links = $t->find_all_links();
    is_deeply( \@links, \@wanted_links, "Correct links came back" );

    my $linkref = $t->find_all_links();
    is_deeply( $linkref, \@wanted_links, "Correct links came back" );
}
