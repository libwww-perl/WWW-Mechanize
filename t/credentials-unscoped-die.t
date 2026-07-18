#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal    qw( exception );
use Test::Warnings qw( :no_end_test had_no_warnings );
use WWW::Mechanize ();

subtest 'two-argument form dies on every call' => sub {
    my $mech = WWW::Mechanize->new;

    like(
        exception { $mech->credentials( 'user', 'pass' ) },
        qr/four-argument form/,
        'two-argument credentials() dies and points at the four-argument form',
    );

    # Not a one-shot warning: a second call dies too.
    isnt(
        exception { $mech->credentials( 'user2', 'pass2' ) },
        undef,
        'two-argument credentials() dies on every call, not just the first',
    );
};

subtest 'a clone also rejects the two-argument form' => sub {
    my $mech  = WWW::Mechanize->new;
    my $clone = $mech->clone;

    isnt(
        exception { $clone->credentials( 'user', 'pass' ) },
        undef,
        'a clone rejects the two-argument form too',
    );
};

subtest 'host-scoped forms are still accepted' => sub {
    my $mech = WWW::Mechanize->new;

    is(
        exception {
            $mech->credentials( 'localhost:80', 'realm', 'user', 'pass' );
        },
        undef,
        'four-argument credentials() does not die',
    );

    is(
        exception { $mech->credentials( 'localhost:80', 'realm' ) },
        undef,
        'two-argument host:port credentials() does not die',
    );
};

had_no_warnings;
done_testing;
