#!perl

use warnings;
use strict;

use lib qw( t/local );

use LocalServer ();
use Path::Tiny qw( path );
use Test::Deep;
use Test::Fatal;
use Test::More;
use URI::file ();
use WWW::Mechanize ();

BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)}
        ;    # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok('WWW::Mechanize');
}

{
    my $mech = WWW::Mechanize->new( cookie_jar => undef, autocheck => 0 );
    isa_ok( $mech, 'WWW::Mechanize' );

    my $uri = URI::file->new_abs('t/history_1.html')->as_string;

    $mech->get($uri);
    ok( $mech->success, "Fetch test page" ) or die q{Can't get test page};

    is( $mech->history_count, 1, "... and it was recorded in the history" );
    cmp_deeply(
        $mech->history(0),
        {
            req => isa('HTTP::Request'),
            res => all(
                isa('HTTP::Response'),
                methods( 'content' => re(qr/Testing the history_1/) ),
            ),
        },
        "... and the first history item is of the correct format"
    );
    $mech->follow_link( n => 1 );

    is( $mech->history_count, 2, "... and it was recorded in the history" );
    cmp_deeply(
        $mech->history(0),
        {
            req => isa('HTTP::Request'),
            res => all(
                isa('HTTP::Response'),
                methods( 'content' => re(qr/Testing the history_2/) ),
            ),
        },
        "... and the second history item is of the correct format"
    );

    ok(
        $mech->submit_form( form_name => "get_form" ),
        "Submit form using 'get' method"
    );

    is( $mech->history_count, 3, "... and it was recorded in the history" );
    cmp_deeply(
        $mech->history(0),
        {
            req => isa('HTTP::Request'),
            res => all(
                isa('HTTP::Response'),
                methods( 'content' => re(qr/Testing the history_3/) ),
            ),
        },
        "... and the third history item is of the correct format"
    );

    is(
        exception {
            $mech->clear_history;
        },
        undef,
        "Clear the history"
    );

    is(
        $mech->history_count, 1,
        "... and the history contains only one item"
    );

    my $history_item_after_clearing = $mech->history(0);
    cmp_deeply(
        $history_item_after_clearing,
        {
            req => isa('HTTP::Request'),
            res => all(
                isa('HTTP::Response'),
                methods( 'content' => re(qr/Testing the history_3/) ),
            ),
        },
        "... and the latest history item is of the correct format"
    );

    cmp_deeply(
        $mech->res,
        $history_item_after_clearing->{res},
        "... and we are still 'displaying' the page we were on when we cleared the history"
    );
    ok( !$mech->back, "... and we cannot go back in the history" );

    $mech->follow_link( n => 1 );
    ok( $mech->success, "Click a link in the page we are 'displaying'" )
        or die q{Can't get test page};
    is( $mech->history_count, 2, "... and it was recorded in the history" );
    like(
        $mech->res->content, qr/Testing the history_1/,
        "... and we are 'displaying' a different page"
    );

    ok( $mech->back, "We can go back in history" );
    cmp_deeply(
        $mech->res,
        $history_item_after_clearing->{res},
        "... and we are 'displaying' the page we were on when we cleared the history again"
    );
}

{
    my $html = path('t/history_2.html')->slurp;
    my $server = LocalServer->spawn( html => $html );
    my $mech = WWW::Mechanize->new( cookie_jar => undef, autocheck => 0 );
    $mech->get( $server->url );

    ok(
        $mech->submit_form( form_name => "post_form" ),
        "Submit form using 'post' method"
    );
    is( $mech->history_count, 2, "... and it was recorded in the history" );
    is(
        $mech->history(0)->{req}->uri, $server->url,
        "... and the correct request was saved"
    );
}

{
    my $mech = WWW::Mechanize->new( cookie_jar => undef, autocheck => 0 );
    isa_ok( $mech, 'WWW::Mechanize' );

    my $uri = URI::file->new_abs('t/history_1.html')->as_string;
    $mech->stack_depth(0);
    is( $mech->stack_depth(), 0, "stack_depth can be changed" );

    $mech->get($uri) for 1, 2, 3;
    is(
        $mech->history_count(), 1,
        "No history saved when history is turned off"
    );

    $mech->stack_depth(1);

    $mech->get($uri) for 1, 2, 3;
    is(
        $mech->history_count(), 2,
        "Limited history is saved when stack_depth is explicitly set"
    );

}

done_testing();
