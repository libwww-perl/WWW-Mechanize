use warnings;
use strict;
use Test::More tests => 12;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

NO_AGENT: {
    my $m = WWW::Mechanize->new;
    isa_ok( $m, 'WWW::Mechanize' );
    can_ok( $m, 'request' );
    like( $m->agent, qr/WWW-Mechanize/, "Set user agent string" );
    like( $m->agent, qr/$WWW::Mechanize::VERSION/, "Set user agent version" );

    $m->agent( "foo/bar v1.23" );
    is( $m->agent, "foo/bar v1.23", "Can set the agent" );
}

SPECIAL_AGENT: {
    my $m = WWW::Mechanize->new( agent => "Windows IE 6" );
    isa_ok( $m, 'WWW::Mechanize' );
    can_ok( $m, 'request');
    unlike( $m->agent, qr/WWW-Mechanize/, "Set user agent string" );
    unlike( $m->agent, qr/$WWW::Mechanize::VERSION/, "Set user agent version" );
    like( $m->agent, qr/^Mozilla.+compatible.+Windows/ ); 

    $m->agent( "ratso/bongo v.43" );
    is( $m->agent, "ratso/bongo v.43", "Can still set the agent" );
}
