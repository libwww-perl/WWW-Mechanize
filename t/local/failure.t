#!perl

use warnings;
use strict;
use Test::More;

use lib 't/local';
use LocalServer;

BEGIN {
    if (gethostbyname('blahblahblah.xx-only-testing.')) {
        plan skip_all => 'Found an A record for the non-existent domain';
    }
    plan tests => 16;
}

BEGIN {
    delete @ENV{ grep { lc eq 'http_proxy' } keys %ENV };
    delete @ENV{ qw( IFS CDPATH ENV BASH_ENV ) };
    use_ok( 'WWW::Mechanize' );
}

my $server = LocalServer->spawn;
isa_ok( $server, 'LocalServer' );


my $mech = WWW::Mechanize->new;
isa_ok( $mech, 'WWW::Mechanize', 'Created object' );

GOOD_PAGE: {
    my $response = $mech->get($server->url);
    isa_ok( $response, 'HTTP::Response' );
    ok( $response->is_success, 'Success' );
    ok( $mech->success, 'Get webpage' );
    ok( $mech->is_html, 'It\'s HTML' );
    is( $mech->title, 'WWW::Mechanize::Shell test page', 'Correct title' );

    my @links = $mech->links;
    is( scalar @links, 10, '10 links, please' );
    my @forms = $mech->forms;
    is( scalar @forms, 1, 'One form' );
    isa_ok( $forms[0], 'HTML::Form' );
}

BAD_PAGE: {
    my $badurl = "http://blahblahblah.xx-only-testing.";
    $mech->get( $badurl );

    ok( !$mech->success, 'Failed the fetch' );
    ok( !$mech->is_html, "Isn't HTML" );
    ok( !defined $mech->title, "No title" );

    my @links = $mech->links;
    is( scalar @links, 0, "No links" );

    my @forms = $mech->forms;
    is( scalar @forms, 0, "No forms" );
}
