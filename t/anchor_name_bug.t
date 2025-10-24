#!perl

use warnings;
use strict;

use Test::More;
use URI::file ();

BEGIN {
    use_ok('WWW::Mechanize');
}

# Test for issue #15: Mechanize seemed to discard the first URL after
# an <a name="anchor"/> tag in a html page.
# See: http://code.google.com/p/www-mechanize/issues/detail?id=15

my $mech = WWW::Mechanize->new( cookie_jar => undef, max_redirect => 0 );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs('t/anchor_name_bug.html')->as_string;

$mech->get($uri);
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

# The bug was that the first link after <a name="anchor"/> was being discarded
my @links = $mech->find_all_links();

# We should find exactly 2 links (test1 and test2), NOT just 1
is( scalar(@links), 2, 'Should find 2 links, not just 1' );

# Verify first link is test1
my $link1 = $mech->find_link( text => 'test1' );
isa_ok( $link1, 'WWW::Mechanize::Link', 'First link (test1) should exist' );
is( $link1->url, 'http://www.url1.com/gi1?a=1', 'First link URL is correct' );

# Verify second link is test2
my $link2 = $mech->find_link( text => 'test2' );
isa_ok( $link2, 'WWW::Mechanize::Link', 'Second link (test2) should exist' );
is( $link2->url, 'http://www.url2.com/gi2?a=2', 'Second link URL is correct' );

# Verify links are in correct order
is( $links[0]->url, 'http://www.url1.com/gi1?a=1', 'First link in order' );
is( $links[1]->url, 'http://www.url2.com/gi2?a=2', 'Second link in order' );

done_testing();
