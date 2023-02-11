#!perl -T

use warnings;
use strict;
use Test::More tests => 8;

BEGIN {
    use_ok('WWW::Mechanize');
}

my @aliases = WWW::Mechanize::known_agent_aliases();
is( scalar @aliases, 6, 'All aliases accounted for' );

for my $alias (@aliases) {
    like(
        $alias, qr/^(Mac|Windows|Linux) /,
        'We only know Mac, Windows or Linux'
    );
}
