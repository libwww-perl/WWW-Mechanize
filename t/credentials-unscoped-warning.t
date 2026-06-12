#!perl

use strict;
use warnings;

use Test::More;
use Test::Warnings qw( :no_end_test warnings );
use WWW::Mechanize ();

subtest 'two-argument form warns once per instance' => sub {
    my $mech = WWW::Mechanize->new;

    my @warnings = warnings { $mech->credentials( 'user', 'pass' ) };
    is scalar @warnings, 1,
        'two-argument credentials() warns on first use';
    like $warnings[0], qr/four-argument form/,
        'warning points at the host-scoped four-argument form';

    @warnings = warnings { $mech->credentials( 'user2', 'pass2' ) };
    is scalar @warnings, 0,
        'two-argument credentials() warns only once per instance';
};

subtest 'a clone warns on its own credentials (flag is not inherited)' =>
    sub {
    my $mech = WWW::Mechanize->new;
    warnings { $mech->credentials( 'user', 'pass' ) };

    my $clone    = $mech->clone;
    my @warnings = warnings {
        $clone->credentials( 'cloneuser', 'clonepass' )
    };
    is scalar @warnings, 1,
        'a clone warns once on its own two-argument credentials() call';
    };

subtest 'host-scoped forms do not warn' => sub {
    my $mech = WWW::Mechanize->new;

    my @warnings = warnings {
        $mech->credentials( 'localhost:80', 'realm', 'user', 'pass' )
    };
    is scalar @warnings, 0,
        'four-argument credentials() does not warn';

    @warnings = warnings {
        $mech->credentials( 'localhost:80', 'realm' )
    };
    is scalar @warnings, 0,
        'two-argument host:port credentials() does not warn';
};

done_testing;
