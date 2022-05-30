package TestServer;
use strict;
use warnings;

use HTTP::Daemon;
use File::Spec;

sub new {
    my $class = shift;
    my $port  = shift;

    my $self = bless {
        port => $port,
    }, $class;

    return $self;
}

sub start {
    my $self = shift;
    die "Already started!"
        if $self->{daemon};

    $self->{daemon} = HTTP::Daemon->new(
        LocalAddr => $self->hostname,
        ( $self->{port} ? ( port => $self->{port} ) : () ),
    );

    return $self->{daemon};
}

sub run {
    my $self = shift;

    $self->start
        if !$self->{daemon};

    my $d = $self->{daemon};

    while (my $c = $d->accept) {
        while (my $r = $c->get_request) {
            $self->handle_request($c, $r);
        }
        $c->close;
        undef($c);
    }

    return;
}

sub handle_request {
    my $self = shift;
    my ($conn, $req) = @_;

    my $path = $req->uri->path;
    my $dispatch_table = $self->{dispatch_table};

    if (my $handler = $dispatch_table->{$path}) {
        my $res = $handler->($req);
        $conn->send_response($res);
    }
    else {
        my $file = $path;
        if ( $file =~ m{/$} ) {
            $file .= 'index.html';
        }
        $file =~ s/\s+//g;

        my $filename = "t/html/$file";
        if ( open my $fh, '<', $filename ) {
            my $content = do { local $/; <$fh> };
            print { $conn } "HTTP/1.0 200 OK\r\n";
            print { $conn } "Content-Type: text/html\r\nContent-Length: ", length($content), "\r\n\r\n", $content;
            return;
        }
        else {
            print { $conn } "HTTP/1.0 404 Not found\r\n";
            print { $conn } "Content-Type: text/plain\r\n";
            print { $conn } "\r\n";
            print { $conn } "Not found\r\n";
            return;
        }
    }
}

sub set_dispatch {
    my $self = shift;
    $self->{dispatch_table} = shift;
    return $self;
}

sub background {
    my $self = shift;

    my $pid = open my $fh, '-|';

    if (!defined $pid) {
        die "Can't start the test server";
    }
    elsif (!$pid) {
        my $daemon = $self->start;
        print "TestServer started: " . $daemon->url . "\n";
        open STDIN, '<', File::Spec->devnull;
        open STDOUT, '>', File::Spec->devnull;
        $self->run; # should never return
        exit 1;
    }

    $self->{pid} = $pid;

    my $status_line = <$fh>;
    chomp $status_line;

    if ($status_line =~ /\ATestServer started: (.*)\z/) {
        $self->{root} = $1;
        $self->{child_fh} = $fh;
    }
    else {
        die "Error starting test server";
    }

    return $pid;
}

sub hostname {
    my $self = shift;

    return '127.0.0.1';
}

sub root {
    my $self = shift;
    $self->{root};
}

sub stop {
    my $self = shift;

    if (my $pid = delete $self->{pid}) {
        kill 9, $pid;
        waitpid $pid, 0;
    }
    if (my $fh = delete $self->{child_fh}) {
        close $fh;
    }
    return;
}

sub DESTROY {
    my $self = shift;
    $self->stop;
}

1;
