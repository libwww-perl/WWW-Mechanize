#!perl -T

use warnings;
use strict;
use Test::More;
use URI::file;
BEGIN { delete @ENV{ qw( http_proxy HTTP_PROXY PATH IFS CDPATH ENV BASH_ENV) }; }

BEGIN {
    eval 'use Test::Warn;';
    plan skip_all => "Test::Warn required to test $0" if $@;
    plan tests => 19;
}

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( 't/find_link.html' )->as_string;

$mech->get( $uri );
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

REGEX_USAGE: {
    for my $tname (qw( TEXT NAME URL TAG )) {
        warning_like(
            sub { $mech->find_link( $tname => 'expect error' ) },
            qr/Unknown link-finding parameter/, "detected usage error: $tname => 'string'"
        );
    }
}

REGEX_STRING: {
    for my $tn (qw( text name url tag )) {
        my $tname = $tn.'_regex';
        warning_like(
            sub { $mech->find_link( $tname => 'expect error' ) },
            qr/passed as $tname is not a regex/, "detected usage error: $tname => 'string'"
        );
    }
}

NON_REGEX_STRING: {
    for my $tname (qw( text name url tag )) {
        warning_like(
            sub { $mech->find_link( $tname => qr/foo/ ) },
            qr/passed as '$tname' is a regex/, "detected usage error: $tname => Regex"
        );
    }
}

SPACE_PADDED: {
    for my $tname (qw( text name url tag )) {
        warning_like(
            sub { $mech->find_link( $tname => ' a padded astring ' ) },
            qr/is space-padded and cannot succeed/, "detected usage error: $tname => padded-string"
        );
    }
}
