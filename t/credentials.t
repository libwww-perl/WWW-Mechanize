#!perl

use warnings;
use strict;

use WWW::Mechanize ();
use Test::More;
use Test::Fatal    qw( exception );
use Test::Warnings qw( :no_end_test had_no_warnings );

my $mech = WWW::Mechanize->new;

my ( $user, $pass );

my $uri = URI->new('http://localhost');

( $user, $pass ) = $mech->get_basic_credentials( 'myrealm', $uri, 0 );
is $user, undef, 'default username is undefined at first';
is $pass, undef, 'default password is undefined at first';

like(
    exception {
        $mech->credentials( 'one', 'two', 'three' );
    },
    qr/Invalid # of args for overridden credentials/,
    'credentials dies with wrong number of args'
);

like(
    exception { $mech->credentials( 'username', 'password' ) },
    qr/four-argument form/,
    'two-argument credentials() dies and points at the four-argument form'
);

# The host-scoped four-argument form is still supported and is stored
# per-instance.
$mech->credentials( 'localhost:80', 'myrealm', 'username', 'password' );

( $user, $pass ) = $mech->get_basic_credentials( 'myrealm', $uri, 0 );
is $user, 'username',
    'four-argument credentials sets username for get_basic_credentials';
is $pass, 'password',
    'four-argument credentials sets password for get_basic_credentials';

my $mech2 = $mech->clone;

( $user, $pass ) = $mech2->get_basic_credentials( 'myrealm', $uri, 0 );
is $user, 'username',
    'cloned object has username for get_basic_credentials';
is $pass, 'password',
    'cloned object has password for get_basic_credentials';

my $mech3 = WWW::Mechanize->new;

( $user, $pass ) = $mech3->get_basic_credentials( 'myrealm', $uri, 0 );
is $user, undef, 'new object has no username for get_basic_credentials';
is $pass, undef, 'new object has no password for get_basic_credentials';

$mech->clear_credentials;

( $user, $pass ) = $mech->get_basic_credentials( 'myrealm', $uri, 0 );
is $user, undef, 'username is undefined after clear_credentials';
is $pass, undef, 'password is undefined after clear_credentials';

( $user, $pass ) = $mech2->get_basic_credentials( 'myrealm', $uri, 0 );
is $user, 'username',
    'cloned object still has username after the original is cleared';
is $pass, 'password',
    'cloned object still has password after the original is cleared';

had_no_warnings;
done_testing;
