package TestServer;

use warnings;
use strict;

use HTTP::Server::Simple::CGI;
use base qw( HTTP::Server::Simple::CGI );

my $dispatch_table = {};

=head1 OVERLOADED METHODS

=cut

sub handle_request {
    my $self = shift;
    my $cgi  = shift;

    my $path = $cgi->path_info();
    my $handler = $dispatch_table->{$path};

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

sub print_banner {
    # Do nothing.  Don't need to pollute the output stream.
}

=head1 METHODS UNIQUE TO TestServer

=cut

sub set_dispatch {
    my $self = shift;
    $dispatch_table = shift;
}

sub spawn {
    my $self = shift;

    my $port = $self->port;
    my $pid = $self->background;

    print "# Server now running on port $port, pid $pid\n";

    return ($port,$pid);
}

1;
