#!perl

use warnings;
use strict;
use Test::More tests => 15;

BEGIN {
    use_ok('WWW::Mechanize');
}

RES_ON_NEW: {
    my $m = WWW::Mechanize->new;
    isa_ok( $m, 'WWW::Mechanize' );

    ok( !$m->success, 'success() is false before any get' );

    my $res = $m->res;
    ok( !defined $res, 'res() is undef' );
}

NO_AGENT: {
    my $m = WWW::Mechanize->new;
    isa_ok( $m, 'WWW::Mechanize' );
    can_ok( $m, 'request' );
    like( $m->agent, qr/WWW-Mechanize/,            'Set user agent string' );
    like( $m->agent, qr/$WWW::Mechanize::VERSION/, 'Set user agent version' );

    $m->agent('foo/bar v1.23');
    is( $m->agent, 'foo/bar v1.23', 'Can set the agent' );

    like( $m->_agent, qr/WWW-Mechanize/, '_agent() is static' );
}

USER_AGENT: {
    my $alias = 'Windows IE 6';
    my $m     = WWW::Mechanize->new( agent => $alias );
    isa_ok( $m, 'WWW::Mechanize' );
    can_ok( $m, 'request' );
    is(
        $m->agent, $alias,
        q{Aliases don't get translated in the constructor}
    );

    $m->agent_alias($alias);
    like(
        $m->agent, qr/^Mozilla.+compatible.+Windows/,
        'Alias sets the agent'
    );

    $m->agent('ratso/bongo v.43');
    is( $m->agent, 'ratso/bongo v.43', 'Can still set the agent' );
}
