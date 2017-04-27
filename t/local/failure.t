use warnings;
use strict;
use Test::More;

use lib 't/local';
use LocalServer;


BEGIN {
    delete @ENV{ qw( IFS CDPATH ENV BASH_ENV ) };
}

my $NONEXISTENT = 'blahblahblah.xx-only-testing.foo.';
my @results = gethostbyname( $NONEXISTENT );
if ( @results ) {
    my ($name,$aliases,$addrtype,$length,@addrs) = @results;
    my $ip = join( '.', unpack('C4',$addrs[0]) );
    plan skip_all => "Your ISP is overly helpful and returns $ip for non-existent domain $NONEXISTENT. This test cannot be run.";
}
my $bad_url = "http://$NONEXISTENT/";

plan tests => 15;
require_ok( 'WWW::Mechanize' );
my $server = LocalServer->spawn;
isa_ok( $server, 'LocalServer' );

my $mech = WWW::Mechanize->new( autocheck => 0 );
isa_ok( $mech, 'WWW::Mechanize', 'Created object' );

GOOD_PAGE: {
    my $response = $mech->get($server->url);
    isa_ok( $response, 'HTTP::Response' );
    ok( $response->is_success, 'Success' );
    ok( $mech->success, 'Get webpage' );
    ok( $mech->is_html, 'It\'s HTML' );
    is( $mech->title, 'WWW::Mechanize test page', 'Correct title' );

    my @links = $mech->links;
    is( scalar @links, 10, '10 links, please' );
    my @forms = $mech->forms;
    is( scalar @forms, 4, 'Four form' );
}

BAD_PAGE: {
    my $bad_url = "http://$NONEXISTENT/";
    $mech->get( $bad_url );

    ok( !$mech->success, 'Failed the fetch' );
    ok( !$mech->is_html, "Isn't HTML" );
    ok( !defined $mech->title, "No title" );

    my @links = $mech->links;
    is( scalar @links, 0, "No links" );

    my @forms = $mech->forms;
    is( scalar @forms, 0, "No forms" );
}
