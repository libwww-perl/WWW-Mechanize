#!/usr/bin/perl -w

use warnings;
use strict;
use Test::More tests => 1;

package MyWebServer;

use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);

my %dispatch = (
    '/feedme' => \&send_cookies,
);

sub handle_request {
    my $self = shift;
    my $cgi  = shift;

    my $path = $cgi->path_info();
    my $handler = $dispatch{$path};

    if (ref($handler) eq "CODE") {
        print "HTTP/1.0 200 OK\r\n";
        $handler->($cgi);
    }
    else {
        print "HTTP/1.0 404 Not found\r\n";
        print
            $cgi->header,
            $cgi->start_html('Not found'),
            $cgi->h1('Not found'),
            $cgi->end_html;
    }
}

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


package main;

use WWW::Mechanize;

# start the server on port 8080
my $server = MyWebServer->new();
my $port = $server->port();
my $pid = $server->background();
diag( "Mech server now running on port $port via pid $pid" );

my $mech = WWW::Mechanize->new( autocheck => 0 );
isa_ok( $mech, 'WWW::Mechanize' );

$mech->get( "http://localhost:$port/feedme" );
is( $mech->status, 200 );
{use Data::Dumper; local $Data::Dumper::Sortkeys=1;
print Dumper( $mech->cookie_jar )}


my $nprocesses = kill 15, $pid;
is( $nprocesses, 1, 'Signaled the child process' );

