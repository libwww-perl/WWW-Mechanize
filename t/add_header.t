#!perl -T

use warnings;
use strict;
use Test::More tests => 4;
use HTTP::Request::Common qw( GET );

BEGIN {
    delete @ENV{qw( PATH IFS CDPATH ENV BASH_ENV )};  # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'WWW::Mechanize' );
}

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize', 'Created agent' );

$agent->add_header( Referer => 'x' );
my $req = GET( 'http://www.google.com/' );
$req = $agent->_modify_request( $req );
like( $req->as_string, qr/Referer/, q{Referer's in there} );

$agent->add_header( Referer => undef );
$req = $agent->_modify_request( $req );
unlike( $req->as_string, qr/Referer/, q{Referer's not there} );
