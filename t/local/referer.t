use warnings;
use strict;
use FindBin ();

use Test::More tests => 14;

use Test::Memory::Cycle;

BEGIN {
    delete @ENV{qw( IFS CDPATH ENV BASH_ENV )};
    use_ok('WWW::Mechanize');
}

our $server;
my $agent = WWW::Mechanize->new();
isa_ok( $agent, 'WWW::Mechanize' );

SKIP: {
    # We want to be safe from non-resolving local host names
    delete $ENV{HTTP_PROXY};

    # Now start a fake webserver, fork, and connect to ourselves
    my $command = qq'"$^X" "$FindBin::Bin/referer-server"';
    if ( $^O eq 'VMS' ) {
        $command = qq'mcr $^X t/referer-server';
    }

    # Set a timeout to ensure we don't hang forever
    local $SIG{ALRM}
        = sub { die "Timeout waiting for test server to start\n" };
    alarm 10;    # 10 second timeout

    open $server, "$command |" or die "Couldn't spawn fake server: $!";

    # Wait for server startup with proper error handling
    my $url = <$server>;
    alarm 0;     # Cancel the alarm

    if ( !defined $url || $url eq '' ) {
        die "Failed to get a response from test server\n";
    }
    chomp $url;

    $agent->get($url);
    is( $agent->status, 200, 'Got first page' ) or diag $agent->res->message;
    is(
        $agent->content, q{Referer: ''},
        'First page gets sent with empty referrer'
    );

    $agent->get($url);
    is( $agent->status, 200, 'Got second page' ) or diag $agent->res->message;
    is(
        $agent->content, "Referer: '$url'",
        'Referer got sent for absolute url'
    );

    $agent->get('.');
    is( $agent->status, 200, 'Got third page' ) or diag $agent->res->message;
    is(
        $agent->content, "Referer: '$url'",
        'Referer got sent for relative url'
    );

    $agent->add_header( Referer => 'x' );
    $agent->get($url);
    is( $agent->status, 200, 'Got fourth page' ) or diag $agent->res->message;
    is(
        $agent->content, q{Referer: 'x'},
        'Referer can be set to empty again'
    );

    my $ref = 'This is not the referer you are looking for *jedi gesture*';
    $agent->add_header( Referer => $ref );
    $agent->get($url);
    is( $agent->status, 200, 'Got fourth page' ) or diag $agent->res->message;
    is( $agent->content, "Referer: '$ref'", 'Custom referer can be set' );

    # Add a timeout for the server shutdown
    local $SIG{ALRM} = sub { die "Timeout waiting for server to quit\n" };
    alarm 5;    # 5 second timeout

    $agent->get( $url . 'quit_server' );
    ok( $agent->success, 'Quit OK' );
}

memory_cycle_ok( $agent, 'No memory cycles found' );

END {
    if ($server) {

        # Make sure we don't hang in END block
        local $SIG{ALRM}
            = sub { warn "Timeout closing server handle\n"; exit 1 };
        alarm 3;
        close $server;
        alarm 0;
    }
}
