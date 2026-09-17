use warnings;
use strict;
use FindBin ();

use Test::More;

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

    open $server, "$command |" or die "Couldn't spawn fake server: $!";
    sleep 1;    # give the child some time
    my $url = <$server>;
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

    # GH #150: a HEAD (or other non-navigational) request must not become
    # the Referer for the next request. Issue the HEAD against a distinct
    # path so a regression would show that path as the Referer.
    $agent->head( $url . 'headcheck' );
    $agent->get($url);
    is(
        $agent->content, "Referer: '$url'",
        'HEAD does not clobber the Referer for the next request'
    );

    # ...and it stays correct across a back().
    $agent->head( $url . 'headcheck' );
    $agent->back();
    $agent->get($url);
    is(
        $agent->content, "Referer: '$url'",
        'HEAD does not clobber the Referer even after back()'
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

    $agent->get( $url . 'quit_server' );
    ok( $agent->success, 'Quit OK' );
}

memory_cycle_ok( $agent, 'No memory cycles found' );

done_testing;

END {
    close $server if $server;
}
