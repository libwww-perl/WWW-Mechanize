use strict;
use warnings;

use constant PAIRS => {
    'http://delicious.com/'
        => 'utf-8',
    'http://www.liveinternet.ru/users/dashdi/blog'
        => '(?:cp|windows-)1251',
};

use Encode;
use Test::More;
use Test::RequiresInternet( 'delicious.com' => 80, 'www.liveinternet.ru' => 80 );

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my %pairs = %{+PAIRS};
for my $url ( sort keys %pairs ) {
    my $want_encoding = $pairs{$url};

    my $mech = WWW::Mechanize->new;
    isa_ok( $mech, 'WWW::Mechanize' );

    $mech->get( $url );
    is( $mech->response->code, 200, "Fetched $url" );

    like( $mech->res->content_charset, qr/$want_encoding/i,
        "   ... Got encoding $want_encoding" );
    ok( Encode::is_utf8( $mech->content ), 'Got back UTF-8' );
}

done_testing();
