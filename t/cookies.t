#!/usr/bin/perl -w

# XXX add cookie reading on the server side to the test

use warnings;
use strict;
use Test::More tests => 14;
use WWW::Mechanize;

use URI::Escape qw( uri_unescape );


use lib 't/lib';
use TestServer;


my $ncookies = 0;

sub send_cookies {
    my $cgi = shift;
    return if !ref $cgi;

    ++$ncookies;

    print
        $cgi->header(
            -cookie => $cgi->cookie(
                -name    => 'my_cookie',
                -value   => "Cookie #$ncookies",
                -domain  => '127.0.0.1',
                -path    => '/',
                -expires => '+1h',
                -secure  => 0,
            )
        ),
        $cgi->start_html( -title => "Home of Cookie #$ncookies" ),
        $cgi->h1( "Here is Cookie #$ncookies" ),
        $cgi->end_html;
}

sub nosend_cookies {
    my $cgi = shift;
    return if !ref $cgi;

    print
        $cgi->header(),
        $cgi->start_html( -title => 'No cookies sent' ),
        $cgi->h1( 'No cookies sent' ),
        $cgi->end_html;
}

# start the server on port 8080
my $server = TestServer->new();
$server->set_dispatch( {
    '/feedme'   => \&send_cookies,
    '/nocookie' => \&nosend_cookies,
} );

my ($port,$pid) = $server->spawn();

my $cookiepage_url   = "http://127.0.0.1:$port/feedme";
my $nocookiepage_url = "http://127.0.0.1:$port/nocookie";

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


my $nprocesses = kill 15, $pid;
is( $nprocesses, 1, 'Signaled the child process' );


sub cookieval {
    my $mech = shift;

    return uri_unescape( $mech->cookie_jar->{COOKIES}{'127.0.0.1'}{'/'}{'my_cookie'}[1] );
}
