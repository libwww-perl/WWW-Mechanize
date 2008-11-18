#!perl -Tw
# WWW::Mechanize tests for <area> tags

use warnings;
use strict;
use Test::More tests => 9;
use URI::file;

BEGIN { delete @ENV{ qw( http_proxy HTTP_PROXY PATH IFS CDPATH ENV BASH_ENV) }; }
BEGIN {
    use_ok( 'WWW::Mechanize' );
}

eval 'use Test::Memory::Cycle';
my $canTMC = !$@;

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( 't/area_link.html' );
$mech->get( $uri );
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};


AREA_CHECKS: {
    my @wanted_links = (
        [ 'http://www.msnbc.com/area', undef, undef, 'area', {
            coords => '1,2,3,4',
            href => 'http://www.msnbc.com/area'
        } ],
        [ 'http://www.cnn.com/area', undef, undef, 'area', {
            coords => '5,6,7,8',
            href => 'http://www.cnn.com/area'
        } ],
        [ 'http://www.cpan.org/area', undef, undef, 'area', {
             '/' => '/',
             coords => '10,11,12,13',
             href => 'http://www.cpan.org/area'
        }  ],
        [ 'http://www.slashdot.org', undef, undef, 'area', {
             href => 'http://www.slashdot.org'
        } ],
        [ 'http://mark.stosberg.com', undef, undef, 'area', {
            alt => q{Mark Stosberg's homepage},
            href => 'http://mark.stosberg.com'
        } ],
    );
    my @links = $mech->find_all_links();

    # Skip the 'base' field for now
    for (@links) {
        my $attrs = $_->[5];
        @{$_} = @{$_}[0..3];
        push @{$_}, $attrs;
    }

    is_deeply( \@links, \@wanted_links, 'Correct links came back' );

    my $linkref = $mech->find_all_links();
    is_deeply( $linkref, \@wanted_links, 'Correct links came back' );

    SKIP: {
        skip 'Test::Memory::Cycle not installed', 2 unless $canTMC;
        memory_cycle_ok( \@links, 'Link list: no cycles' );
        memory_cycle_ok( $linkref, 'Single link: no cycles' );
    }
}

SKIP: {
    skip 'Test::Memory::Cycle not installed', 2 unless $canTMC;

    memory_cycle_ok( $uri, 'URI: no cycles' );
    memory_cycle_ok( $mech, 'Mech: no cycles' );
}
