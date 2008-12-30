package TestServer;

use warnings;
use strict;

BEGIN {
    delete $ENV{http_proxy}; # All our tests are running on localhost
}

use base 'HTTP::Server::Simple::CGI';

use Carp ();

our $pid;

sub new {
    my $class = shift;

    die 'An instance of TestServer has already been started.' if $pid;

    return $class->SUPER::new(@_);
}

sub run {
    my $self = shift;

    $pid = $self->SUPER::run(@_);

    $SIG{__DIE__} = \&stop;

    return $pid;
}

sub handle_request {
    my $self = shift;
    my $cgi  = shift;

    my $file = (split( /\//,$cgi->path_info))[-1]||'index.html';
    $file    =~ s/\s+//g;

    my $filename = "t/html/$file";
    if ( -r $filename ) {
        if (my $response=do { local (@ARGV, $/) = $filename; <> }) {
            print "HTTP/1.0 200 OK\r\n";
            print "Content-Type: text/html\r\nContent-Length: ", length($response), "\r\n\r\n", $response;
            return;
        }
    }

    print "HTTP/1.0 404 Not Found\r\n\r\n";

    return;
}

sub background {
    my $self = shift;

    $pid = $self->SUPER::background()
        or Carp::confess( q{Can't start the test server} );

    sleep 1; # background() may come back prematurely, so give it a second to fire up

    return $pid;
}

sub root {
    my $self = shift;
    my $port = $self->port;

    return "http://localhost:$port";
}

sub stop {
    if ( $pid ) {
        kill( 9, $pid ) unless $^S;
        undef $pid;
    }

    return;
}

1;
