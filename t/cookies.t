#!/usr/bin/perl -w

use warnings;
use strict;
use Test::More tests => 10;
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
                -name  => 'my_cookie',
                -value => "Cookie #$ncookies",
            ) ),
        $cgi->start_html( -title => "Home of Cookie #$ncookies" ),
        $cgi->h1( "Here is Cookie #$ncookies" ),
        $cgi->end_html;
}


# start the server on port 8080
my $server = TestServer->new();
$server->set_dispatch( {
    '/feedme' => \&send_cookies,
} );

my ($port,$pid) = $server->spawn();

my $feedme_url = "http://localhost:$port/feedme";
my $mech = WWW::Mechanize->new( autocheck => 0 );
isa_ok( $mech, 'WWW::Mechanize' );

FIRST_COOKIE: {
    $mech->get( $feedme_url );
    is( $mech->status, 200, 'First fetch works' );

    my $cookie = $mech->cookie_jar->{COOKIES}{'localhost.local'}{'/'}{'my_cookie'};
    my $value = uri_unescape( $cookie->[1] );

    is( $value, 'Cookie #1', 'First cookie matches' );
    is( $mech->title, 'Home of Cookie #1', 'Right title' );
}

SECOND_COOKIE: {
    $mech->get( $feedme_url );
    is( $mech->status, 200, 'Second fetch works' );

    my $cookie = $mech->cookie_jar->{COOKIES}{'localhost.local'}{'/'}{'my_cookie'};
    my $value = uri_unescape( $cookie->[1] );

    is( $value, 'Cookie #2', 'Second cookie matches' );
    is( $mech->title, 'Home of Cookie #2', 'Right title' );
}

BACK_TO_FIRST_PAGE: {
    $mech->back();

    my $cookie = $mech->cookie_jar->{COOKIES}{'localhost.local'}{'/'}{'my_cookie'};
    my $value = uri_unescape( $cookie->[1] );

    is( $value, 'Cookie #2', 'Cookie did not change...' );
    is( $mech->title, 'Home of Cookie #1', '... but back to the first page title' );
}

my $nprocesses = kill 15, $pid;
is( $nprocesses, 1, 'Signaled the child process' );

