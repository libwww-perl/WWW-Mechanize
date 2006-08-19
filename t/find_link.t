#!perl -Tw

use warnings;
use strict;
use Test::More tests => 59;
use URI::file;

BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};  # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( 't/find_link.html' )->as_string;

$mech->get( $uri );
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

my $x;
$x = $mech->find_link();
isa_ok( $x, 'WWW::Mechanize::Link' );
is( $x->[0], 'http://www.drphil.com/', 'First link on the page' );
is( $x->url, 'http://www.drphil.com/', 'First link on the page' );

$x = $mech->find_link( url_regex => qr/upcase/i );
isa_ok( $x, 'WWW::Mechanize::Link' );
like( $x->url, qr/upcase.com/i, 'found link in uppercase meta tag' ); 

$x = $mech->find_link( text => 'CPAN A' );
isa_ok( $x, 'WWW::Mechanize::Link' );
is( $x->[0], 'http://a.cpan.org/', 'First CPAN link' );
is( $x->url, 'http://a.cpan.org/', 'First CPAN link' );

$x = $mech->find_link( url => 'CPAN' );
ok( !defined $x, 'No url matching CPAN' );

$x = $mech->find_link( text_regex => qr/CPAN/, n=>3 );
isa_ok( $x, 'WWW::Mechanize::Link' );
is( $x->[0], 'http://c.cpan.org/', '3rd CPAN text' );
is( $x->url, 'http://c.cpan.org/', '3rd CPAN text' );

$x = $mech->find_link( text => 'CPAN', n=>34 );
ok( !defined $x, 'No 34th CPAN text' );

$x = $mech->find_link( text_regex => qr/(?i:cpan)/ );
isa_ok( $x, 'WWW::Mechanize::Link' );
is( $x->[0], 'http://a.cpan.org/', 'Got 1st cpan via regex' );
is( $x->url, 'http://a.cpan.org/', 'Got 1st cpan via regex' );

$x = $mech->find_link( text_regex => qr/cpan/i );
isa_ok( $x, 'WWW::Mechanize::Link' );
is( $x->[0], 'http://a.cpan.org/', 'Got 1st cpan via regex' );
is( $x->url, 'http://a.cpan.org/', 'Got 1st cpan via regex' );

$x = $mech->find_link( text_regex => qr/cpan/i, n=>153 );
ok( !defined $x, 'No 153rd cpan link' );

$x = $mech->find_link( url => 'http://b.cpan.org/' );
isa_ok( $x, 'WWW::Mechanize::Link' );
is( $x->[0], 'http://b.cpan.org/', 'Got b.cpan.org' );
is( $x->url, 'http://b.cpan.org/', 'Got b.cpan.org' );

$x = $mech->find_link( url => 'http://b.cpan.org', n=>2 );
ok( !defined $x, 'Not a second b.cpan.org' );

$x = $mech->find_link( url_regex => qr/[b-d]\.cpan\.org/, n=>2 );
isa_ok( $x, 'WWW::Mechanize::Link' );
is( $x->[0], 'http://c.cpan.org/', 'Got c.cpan.org' );
is( $x->url, 'http://c.cpan.org/', 'Got c.cpan.org' );

my @wanted_links= (
   [ 'http://a.cpan.org/', 'CPAN A', undef, 'a' ], 
   [ 'http://b.cpan.org/', 'CPAN B', undef, 'a' ], 
   [ 'http://c.cpan.org/', 'CPAN C', 'bongo', 'a' ], 
   [ 'http://d.cpan.org/', 'CPAN D', undef, 'a' ], 
);
my @links = $mech->find_all_links( text_regex => qr/CPAN/ );
@{$_} = @{$_}[0..3] for @links;
is_deeply( \@links, \@wanted_links, 'Correct links came back' );

my $linkref = $mech->find_all_links( text_regex => qr/CPAN/ );
is_deeply( $linkref, \@wanted_links, 'Correct links came back' );

# Check combinations of links
$x = $mech->find_link( text => 'News' );
isa_ok( $x, 'WWW::Mechanize::Link' );
is( $x->[0], 'http://www.msnbc.com/', 'First News is MSNBC' );
is( $x->url, 'http://www.msnbc.com/', 'First News is MSNBC' );

$x = $mech->find_link( text => 'News', url_regex => qr/bbc/ );
isa_ok( $x, 'WWW::Mechanize::Link' );
is( $x->[0], 'http://www.bbc.co.uk/', 'First BBC news link' );
is( $x->url, 'http://www.bbc.co.uk/', 'First BBC news link' );
is( $x->[1], 'News', 'First BBC news text' );
is( $x->text, 'News', 'First BBC news text' );

$x = $mech->find_link( text => 'News', url_regex => qr/cnn/ );
isa_ok( $x, 'WWW::Mechanize::Link' );
is( $x->[0], 'http://www.cnn.com/', 'First CNN news link' );
is( $x->url, 'http://www.cnn.com/', 'First CNN news link' );
is( $x->[1], 'News', 'First CNN news text' );
is( $x->text, 'News', 'First CNN news text' );

AREA_CHECKS: {
    my @wanted_links = (
        [ 'http://www.cnn.com/', 'CNN', undef, 'a' ],
        [ 'http://www.cnn.com/', 'News', 'Fred', 'a' ],
        # Can someone confirm that I just fixed a bug here, and
        # area tags /should/ have names? -mls
        [ 'http://www.cnn.com/area', undef, 'Marty', 'area' ],
    );
    my @links = $mech->find_all_links( url_regex => qr/cnn\.com/ );
    @{$_} = @{$_}[0..3] for @links;
    is_deeply( \@links, \@wanted_links, 'Correct links came back' );
}

$x = $mech->find_link( name => 'bongo' );
isa_ok( $x, 'WWW::Mechanize::Link' );
is_deeply( $x, [ 'http://c.cpan.org/', 'CPAN C', 'bongo', 'a' ], 'Got the CPAN C link' );

$x = $mech->find_link( name_regex => qr/^[A-Z]/, n => 2 );
isa_ok( $x, 'WWW::Mechanize::Link' );
is_deeply( $x, [ 'http://www.cnn.com/', 'News', 'Fred', 'a' ], 'Got 2nd link that begins with a capital' );

$x = $mech->find_link( tag => 'a', n => 3 );
isa_ok( $x, 'WWW::Mechanize::Link' );
is_deeply( $x, [ 'http://b.cpan.org/', 'CPAN B', undef, 'a' ], 'Got 3rd <A> tag' );

$x = $mech->find_link( tag_regex => qr/^(a|frame)$/, n => 7 );
isa_ok( $x, 'WWW::Mechanize::Link' );
is_deeply( $x, [ 'http://d.cpan.org/', 'CPAN D', undef, 'a' ], 'Got 7th <A> or <FRAME> tag' );

$x = $mech->find_link( text => 'Rebuild Index' );
isa_ok( $x, 'WWW::Mechanize::Link' );
is_deeply( [@{$x}[0..3]], [ '/cgi-bin/MT/mt.cgi', 'Rebuild Index', undef, 'a' ], 'Got the JavaScript link' );

$x = $mech->find_link( url => 'blongo.html' );
isa_ok( $x, 'WWW::Mechanize::Link' );

$x = $mech->find_link( url_abs => 'blongo.html' );
ok( !defined $x, 'No match' );

$x = $mech->find_link( url_abs_regex => qr[t/blongo\.html$] );
isa_ok( $x, 'WWW::Mechanize::Link' );
