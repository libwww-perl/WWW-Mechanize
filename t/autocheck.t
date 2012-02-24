#!perl -Tw

use warnings;
use strict;
use Test::More;


BEGIN { delete @ENV{ qw( http_proxy HTTP_PROXY ) }; }
BEGIN {
    eval 'use Test::Exception';
    plan skip_all => 'Test::Exception required to test autocheck' if $@;
}


my $NONEXISTENT = 'blahblablah.xx-nonexistent.foo';
my @results = gethostbyname( $NONEXISTENT );
if ( @results ) {
    my ($name,$aliases,$addrtype,$length,@addrs) = @results;
    my $ip = join( '.', unpack('C4',$addrs[0]) );
    plan skip_all => "Your ISP is overly helpful and returns $ip for non-existent domain $NONEXISTENT. This test cannot be run.";
}
my $bad_url = "http://$NONEXISTENT/";

plan tests => 10;
require_ok( 'WWW::Mechanize' );

AUTOCHECK_OFF: {
    my $mech = WWW::Mechanize->new( autocheck => 0 );
    isa_ok( $mech, 'WWW::Mechanize' );

    $mech->get( $bad_url );
    ok( !$mech->success, qq{Didn't fetch $bad_url, but didn't die, either} );
}

AUTOCHECK_ON: {
    my $mech = WWW::Mechanize->new;
    isa_ok( $mech, 'WWW::Mechanize' );

    dies_ok {
        $mech->get( $bad_url );
    } qq{Couldn't fetch $bad_url, and died as a result};
}

AUTOCHECK_CHANGE: {
    my $mech = WWW::Mechanize->new;
    isa_ok( $mech, 'WWW::Mechanize' );

    $mech->autocheck( 0 );

    $mech->get( $bad_url );
    ok( !$mech->success, qq{Didn't fetch $bad_url, but didn't die, either} );

    $mech->autocheck( 1 );

    dies_ok {
        $mech->get( $bad_url );
    } qq{Couldn't fetch $bad_url, and died as a result};

    ok( $mech->autocheck(), 'autocheck getter correctly returns true' );
    $mech->autocheck( 0 );
    ok( !$mech->autocheck(), 'autocheck getter correctly returns false' );
}
