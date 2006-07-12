#!perl -Tw

use warnings;
use strict;

use Test::More tests => 6;
use URI::file;

BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)}; # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( "t/image-parse.html" )->as_string;

$mech->get( $uri );
ok( $mech->success, "Fetched $uri" ) or die "Can't get test page";

$mech->get( "select.html" );
ok( $mech->success, "Fetch select.html, no directory" );

$mech->get( "./select.html" );
ok( $mech->success, "Fetch select.html from ./" );

$mech->get( "local/click.t" );
ok( $mech->success, "Fetched click.t" );
