use warnings;
use strict;
use Test::More;

use lib 't/local';
use LocalServer ();

BEGIN {
    delete @ENV{qw( IFS CDPATH ENV BASH_ENV )};
    use_ok('WWW::Mechanize');
}

my $server = LocalServer->spawn;
isa_ok( $server, 'LocalServer' );

STANDARD_STACK: {
    my $history;
    my $mech = WWW::Mechanize->new;
    isa_ok( $mech, 'WWW::Mechanize', 'Created object' );

    is( scalar @{ $mech->{page_stack} }, 0,     'Page stack starts empty' );
    is( $mech->history_count,            0,     'No history count to start' );
    is( $mech->history(0),               undef, 'No 0th history item yet' );

    ok( $mech->get( $server->url )->is_success, 'Got start page' );
    is(
        scalar @{ $mech->{page_stack} }, 0,
        'Page stack empty after first get'
    );
    $history = $mech->history(0);
    is( $history->{req}->url, $server->url, "0th history is last request" );
    is( $mech->history(1),    undef,        'No 1th history item yet' );

    is( $mech->history_count, 1, 'One history count after first get' );
    $mech->_push_page_stack();
    is( scalar @{ $mech->{page_stack} }, 1, 'Pushed item onto page stack' );
    is( $mech->history_count,            2, 'Two history count after push' );
    $mech->_push_page_stack();
    is( scalar @{ $mech->{page_stack} }, 2, 'Pushed item onto page stack' );
    is( $mech->history_count, 3, 'Three history count after push' );
    $mech->back();
    is( scalar @{ $mech->{page_stack} }, 1, 'Popped item from page stack' );
    is( $mech->history_count, 2, 'History count back to 2 post pop' );
    $mech->back();
    is( scalar @{ $mech->{page_stack} }, 0, 'Popped item from page stack' );
    is( $mech->history_count, 1, 'History count back to 1 post pop' );
    $mech->back();
    is(
        scalar @{ $mech->{page_stack} }, 0,
        'Cannot pop beyond end of page stack'
    );
    is( $mech->history_count, 1, 'History count stable at 1' );
}

NO_STACK: {
    my $mech = WWW::Mechanize->new;
    isa_ok( $mech, 'WWW::Mechanize', 'Created object' );
    $mech->stack_depth(0);

    is( scalar @{ $mech->{page_stack} }, 0, 'Page stack starts empty' );
    ok( $mech->get( $server->url )->is_success, 'Got start page' );
    is( scalar @{ $mech->{page_stack} }, 0, 'Page stack starts empty' );
    $mech->_push_page_stack();
    is( scalar @{ $mech->{page_stack} }, 0, 'Pushing has no effect' );
}

done_testing;
