use warnings;
use strict;
use Test::More tests => 17;

use lib 't/lib';
use Test::HTTP::LocalServer;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $server = Test::HTTP::LocalServer->spawn;
isa_ok( $server, 'Test::HTTP::LocalServer' );


my $a = WWW::Mechanize->new;
isa_ok( $a, 'WWW::Mechanize', 'Created object' );

GOOD_PAGE: {
    my $response = $a->get($server->url);
    isa_ok( $response, 'HTTP::Response' );
    ok( $response->is_success, "Success" );
    ok( $a->success, "Get webpage" );
    is( ref $a->uri, "", "URI should be a plain scalar, not an object");
    ok( $a->is_html, "It's HTML" );
    is( $a->title, "WWW::Mechanize::Shell test page", "Correct title" );

    my @links = $a->links;
    is( scalar @links, 8, "eight links, please" );
    my @forms = $a->forms;
    is( scalar @forms, 1, "One form" );
    isa_ok( $forms[0], 'HTML::Form' );
}

BAD_PAGE: {
    my $badurl = "http://sdlfkjsdlfjks.blofgorongotron.xx-only-testing";
    $a->get( $badurl );

    ok( !$a->success, 'Failed the fetch' );
    ok( !$a->is_html, "Isn't HTML" );
    ok( !defined $a->title, "No title" );

    my @links = $a->links;
    is( scalar @links, 0, "No links" );

    my @forms = $a->forms;
    is( scalar @forms, 0, "No forms" );
}
