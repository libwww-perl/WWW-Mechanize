#!/usr/bin/perl -w

use warnings;
use strict;
use Test::More tests => 3;
use WWW::Mechanize;


use lib 't/lib';
use TestServer;


sub send_cookies {
    my $cgi = shift;
    return if !ref $cgi;

    print
        $cgi->header(
            -cookie => $cgi->cookie(
                -name => 'my_cookie',
                -value => 'ANOTHER COOKIE',
            ) ),
        $cgi->start_html( 'Hello' ),
        $cgi->h1( 'Have a cookie' ),
        $cgi->end_html;
}


# start the server on port 8080
my $server = TestServer->new();
$server->set_dispatch( {
    '/feedme' => \&send_cookies,
} );

my ($port,$pid) = $server->spawn();

my $mech = WWW::Mechanize->new( autocheck => 0 );
isa_ok( $mech, 'WWW::Mechanize' );

$mech->get( "http://localhost:$port/feedme" );
is( $mech->status, 200 );
{use Data::Dumper; local $Data::Dumper::Sortkeys=1;
    print Dumper( $mech->cookie_jar )}


my $nprocesses = kill 15, $pid;
is( $nprocesses, 1, 'Signaled the child process' );

