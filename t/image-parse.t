#!perl -Tw

use warnings;
use strict;

use Test::More tests=>3;
use URI::file;

BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};  # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( "t/image-parse.html" )->as_string;

$mech->get( $uri );
ok( $mech->success, "Fetched $uri" ) or die "Can't get test page";
