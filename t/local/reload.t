use warnings;
use strict;
use Test::More tests => 15;

use lib qw( t/local );
use LocalServer ();

use Test::Memory::Cycle;

BEGIN {
    delete @ENV{ qw( IFS CDPATH ENV BASH_ENV ) };
    use_ok( 'WWW::Mechanize' );
}

my $server = LocalServer->spawn;
isa_ok( $server, 'LocalServer' );

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize', 'Created object' );

NO_GET: {
    my $r = $agent->reload;
    ok( !defined($r), 'Initial reload should fail' );
}

FIRST_GET: {
    my $r = $agent->get($server->url);
    isa_ok( $r, 'HTTP::Response' );
    ok( $r->is_success, 'Get google webpage');
    ok( $agent->is_html, 'Valid HTML' );
    is( $agent->title, 'WWW::Mechanize test page' );
}

INVALIDATE: {
    undef $agent->{content};
    undef $agent->{ct};
    isnt( $agent->title, 'WWW::Mechanize test page' );
    ok( !$agent->is_html, 'Not HTML' );
}

RELOAD: {
    my $r = $agent->reload;
    isa_ok( $r, 'HTTP::Response' );
    ok( $agent->is_html, 'Valid HTML' );
    ok( $agent->title, 'WWW::Mechanize test page' );
    my $cookie_before = $agent->history(0)->{req}->header('Cookie');
    $agent->reload;
    my $cookie_after = $agent->history(0)->{req}->header('Cookie');
    is( $cookie_after, $cookie_before, 'cookies are not multiplied' );
}

memory_cycle_ok( $agent, 'Mech: no cycles' );
