use strict;
use warnings;

use Test::More;
use Test::Fatal    qw( exception );
use Test::Warnings qw( :no_end_test had_no_warnings );
use LWP::UserAgent ();
use WWW::Mechanize ();
use URI            ();

# Each WWW::Mechanize instance keeps its own host-scoped credentials; one
# instance's credentials never leak into another.  (Historically a
# monkeypatch let only one LWP::UserAgent descendant hold credentials; this
# test checks that buggy behaviour is gone.)

my $uri   = URI->new('http://localhost');
my $realm = 'myrealm';

my $ua = LWP::UserAgent->new();
$ua->credentials( $uri, $realm, 'user', 'pass' );

my $mech1 = WWW::Mechanize->new();
my $mech2 = WWW::Mechanize->new();
my $mech3 = WWW::Mechanize->new();

$mech1->credentials( 'localhost:80', $realm, 'mech1', 'mech1' );
$mech2->credentials( 'localhost:80', $realm, 'mech2', 'mech2' );

is_deeply(
    [ $ua->credentials( $uri, $realm ) ], [ 'user', 'pass' ],
    'LWP::UserAgent instance retains its old credentials'
);

is_deeply(
    [ $mech1->get_basic_credentials( $realm, $uri ) ],
    [ 'mech1', 'mech1' ], 'First instance retains its credentials'
);
is_deeply(
    [ $mech2->get_basic_credentials( $realm, $uri ) ],
    [ 'mech2', 'mech2' ], 'Second instance retains its credentials'
);
is_deeply(
    [ $mech3->get_basic_credentials( $realm, $uri ) ], [],
    'Untouched instance has no credentials'
);

# The insecure, unscoped two-argument form is rejected outright.
like(
    exception { $mech1->credentials( 'user', 'pass' ) },
    qr/four-argument form/,
    'two-argument credentials() dies'
);

had_no_warnings;
done_testing;
