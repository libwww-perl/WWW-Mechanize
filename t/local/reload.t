use warnings;
use strict;
use Test::More tests => 16;

use lib 't/local';
use LocalServer;

BEGIN { delete @ENV{ qw( http_proxy HTTP_PROXY ) }; }
BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $server = LocalServer->spawn;
isa_ok( $server, 'LocalServer' );

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize', 'Created object' );

NO_GET: {
    my $r = $agent->reload;
    ok( !defined($r), "Initial reload should fail" );
}

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

SKIP: {
    eval "use Test::Memory::Cycle";
    skip "Test::Memory::Cycle not installed", 1 if $@;

    memory_cycle_ok( $agent, "Mech: no cycles" );
}
