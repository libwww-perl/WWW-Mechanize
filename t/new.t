use warnings;
use strict;
use Test::More tests => 5;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $agent = WWW::Mechanize->new;
isa_ok( $agent, 'WWW::Mechanize', 'Created object' );
can_ok($agent, 'request');  # as a subclass of LWP::UserAgent
like($agent->agent(), qr/WWW-Mechanize/, "Set user agent string");
like($agent->agent(), qr/$WWW::Mechanize::VERSION/, "Set user agent version");
