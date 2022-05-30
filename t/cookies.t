# XXX add cookie reading on the server side to the test

BEGIN { delete @ENV{ qw( http_proxy HTTP_PROXY ) }; }

use warnings;
use strict;
use Test::More;

if ( $^O =~ /Win32/ ) {
    plan skip_all => 'HTTP::Server::Simple does not support Windows yet.';
}
else {
    plan tests => 14;
}

use WWW::Mechanize;
use URI::Escape qw( uri_unescape uri_escape );

use lib 't/';
use TestServer;

my $ncookies = 0;

sub send_cookies {
    my $req = shift;

    ++$ncookies;
    my $cvalue = uri_escape("Cookie #$ncookies");

    HTTP::Response->new(
        200, 'OK',
        [
            'Content-Type' => 'text/html',
            'Set-Cookie' => "my_cookie=$cvalue; Path=/; Domain=127.0.0.1; Expires=+1h;",
        ],
        <<"END_HTML",
<html>
<head>
    <title>Home of Cookie #$ncookies</title>
</head>
<body>
    <h1>Here is Cookie #$ncookies</h1>
</body>
</html>
END_HTML
    );
}

sub nosend_cookies {
    HTTP::Response->new(
        200, 'OK',
        [ 'Content-Type' => 'text/html' ],
        <<"END_HTML",
<html>
<head>
    <title>No cookies sent</title>
</head>
<body>
    <h1>No cookies sent</h1>
</body>
</html>
END_HTML
    );
}

my $server = TestServer->new();
$server->set_dispatch( {
    '/feedme'   => \&send_cookies,
    '/nocookie' => \&nosend_cookies,
} );
my $pid = $server->background();

my $root             = $server->root;

my $cookiepage_url   = $root . 'feedme';
my $nocookiepage_url = $root . 'nocookie';

my $mech = WWW::Mechanize->new( autocheck => 0 );
isa_ok( $mech, 'WWW::Mechanize' );

FIRST_COOKIE: {
    $mech->get( $cookiepage_url );
    is( $mech->status, 200, 'First fetch works' );

    my $cookieval = cookieval( $mech );

    is( $cookieval, 'Cookie #1', 'First cookie matches' );
    is( $mech->title, 'Home of Cookie #1', 'Right title' );
}

SECOND_COOKIE: {
    $mech->get( $cookiepage_url );
    is( $mech->status, 200, 'Second fetch works' );

    my $cookieval = cookieval( $mech );

    is( $cookieval, 'Cookie #2', 'Second cookie matches' );
    is( $mech->title, 'Home of Cookie #2', 'Right title' );
}

BACK_TO_FIRST_PAGE: {
    $mech->back();

    my $cookieval = cookieval( $mech );

    is( $cookieval, 'Cookie #2', 'Cookie did not change...' );
    is( $mech->title, 'Home of Cookie #1', '... but back to the first page title' );
}

FORWARD_TO_NONCOOKIE_PAGE: {
    $mech->get( $nocookiepage_url );

    my $cookieval = cookieval( $mech );

    is( $cookieval, 'Cookie #2', 'Cookie did not change...' );
    is( $mech->title, 'No cookies sent', 'On the proper 3rd page' );
}

GET_A_THIRD_COOKIE: {
    $mech->get( $cookiepage_url );

    my $cookieval = cookieval( $mech );

    is( $cookieval, 'Cookie #3', 'Got the third cookie' );
    is( $mech->title, 'Home of Cookie #3', 'Title is correct' );
}


my $signal = ($^O eq 'MSWin32') ? 9 : 15;
my $nprocesses = kill $signal, $pid;
is( $nprocesses, 1, 'Signaled the child process' );


sub cookieval {
    my $mech = shift;

    return uri_unescape( $mech->cookie_jar->{COOKIES}{'127.0.0.1'}{'/'}{'my_cookie'}[1] );
}
