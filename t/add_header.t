use warnings;
use strict;
use Test::More tests => 3;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $agent = WWW::Mechanize->new;
isa_ok( $agent, "WWW::Mechanize", "Created agent" );

$agent->add_header(foo => 'bar');
is($WWW::Mechanize::headers{'foo'}, 'bar', "set header");
