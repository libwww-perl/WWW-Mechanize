use warnings;
use strict;
use Test::More tests => 13;

use lib 't/lib';
use Test::HTTP::LocalServer;
my $server = Test::HTTP::LocalServer->spawn;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize', 'Created object' );

FIRST_GET: {
    my $r = $agent->get($server->url);
    isa_ok( $r, "HTTP::Response" );
    ok( $r->is_success, "Get google webpage");
    is( ref $agent->uri, "", "URI should be string, not an object" );
    ok( $agent->is_html );
    is( $agent->title, "WWW::Mechanize::Shell test page" );
}

INVALIDATE: {
    undef $agent->{content};
    undef $agent->{ct};
    isnt( $agent->title, "WWW::Mechanize::Shell test page" );
    ok( !$agent->is_html );
}

RELOAD: {
    my $r = $agent->reload;
    isa_ok( $r, "HTTP::Response" );
    is( ref $agent->uri, "", "URI shouldn't be an object" );
    ok( $agent->is_html );
    ok( $agent->title, "WWW::Mechanize::Shell test page" );
}
