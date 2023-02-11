#!perl -T

use warnings;
use strict;

use WWW::Mechanize ();
use Test::More;
use Test::Fatal qw( exception );

my $mech = WWW::Mechanize->new;
isa_ok( $mech, 'WWW::Mechanize' );

my ( $user, $pass );

my $uri = URI->new('http://localhost');

( $user, $pass ) = $mech->get_basic_credentials( 'myrealm', $uri, 0 );
is $user, undef, 'default username is undefined at first';
is $pass, undef, 'default password is undefined at first';

like(
    exception {
        $mech->credentials( "one", "two", "three" );
    },
    qr/Invalid # of args for overridden credentials/,
    'credentials dies with wrong number of args'
);

$mech->credentials( "username", "password" );

( $user, $pass ) = $mech->get_basic_credentials( 'myrealm', $uri, 0 );
is $user, 'username',
    'calling credentials sets username for get_basic_credentials';
is $pass, 'password',
    'calling credentials sets password for get_basic_credentials';

my $mech2 = $mech->clone;

( $user, $pass ) = $mech2->get_basic_credentials( 'myrealm', $uri, 0 );
is $user, 'username',
    'cloned object has username for get_basic_credentials';
is $pass, 'password',
    'cloned object has password for get_basic_credentials';

my $mech3 = WWW::Mechanize->new;
isa_ok( $mech3, 'WWW::Mechanize' );

( $user, $pass ) = $mech3->get_basic_credentials( 'myrealm', $uri, 0 );
is $user, undef, 'new object has no username for get_basic_credentials';
is $pass, undef, 'new object has no password for get_basic_credentials';

$mech->clear_credentials;

( $user, $pass ) = $mech->get_basic_credentials( 'myrealm', $uri, 0 );
is $user, undef, 'username is undefined after clear_credentials';
is $pass, undef, 'password is undefined after clear_credentials';

( $user, $pass ) = $mech2->get_basic_credentials( 'myrealm', $uri, 0 );
is $user, 'username',
    'cloned object still has username for get_basic_credentials';
is $pass, 'password',
    'cloned object still has password for get_basic_credentials';

done_testing;
