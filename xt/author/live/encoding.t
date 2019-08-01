use strict;
use warnings;

use constant PAIRS => {
    'https://www.tripadvisor.com/'     => 'utf-8',
    'https://www.liveinternet.ru/top/' => 'cp1251',
};

use Encode;
use Test::More;
use Test::Needs 'LWP::Protocol::https';
use Test::RequiresInternet(
    'www.tripadvisor.com' => 443,
    'www.liveinternet.ru' => 443
);
use WWW::Mechanize;

my %pairs = %{ +PAIRS };
for my $url ( sort keys %pairs ) {
    subtest $url => sub {
        my $want_encoding = $pairs{$url};

        my $mech = WWW::Mechanize->new;

        $mech->get($url);
        is( $mech->response->code, 200, "Fetched $url" );

        like(
            $mech->res->content_charset, qr/$want_encoding/i,
            "   ... Got encoding $want_encoding"
        );
        ok( Encode::is_utf8( $mech->content ), 'Got back UTF-8' );
    };
}

done_testing();
