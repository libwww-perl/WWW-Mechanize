use strict;
use warnings;

use Test::More;
use Test::Warnings qw( :no_end_test warnings );
use LWP::UserAgent ();
use WWW::Mechanize ();
use URI            ();

# The monkeypatch introduced since at least WWW::Mechanize 1.34 only
# ever allows one instance of every LWP::UserAgent descendant to have
# credentials.  This test checks that this buggy behaviour is gone.

my $uri   = URI->new('http://localhost');
my $realm = 'myrealm';

my $ua = LWP::UserAgent->new();
$ua->credentials( $uri, $realm, 'user', 'pass' );

my $mech1 = WWW::Mechanize->new();
my $mech2 = WWW::Mechanize->new();
my $mech3 = WWW::Mechanize->new();

my @warnings = warnings {
    $mech1->credentials( 'mech1', 'mech1' );
    $mech1->credentials( 'mech1', 'mech1' );
    $mech2->credentials( 'mech2', 'mech2' );
    $mech2->credentials( 'mech2', 'mech2' );
};

is scalar @warnings, 2,
    'two-argument credentials() warns once per instance';

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
    'Untouched instance retains its credentials'
);

done_testing;
