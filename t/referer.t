#!/usr/bin/perl -w
use strict;
use FindBin;

use Test::More tests => 16;
use_ok('WWW::Mechanize');

SKIP: {
    eval { require HTTP::Daemon; };
    skip "HTTP::Daemon required to test the referrer header",10
	if ($@);

    # We want to be safe from non-resolving local host names
    delete $ENV{HTTP_PROXY};

    # Now start a fake webserver, fork, and connect to ourselves
    open SERVER, qq'"$^X" $FindBin::Bin/referer-server |'
	or die "Couldn't spawn fake server : $!";
    sleep 1; # give the child some time
    my $url = <SERVER>;
    chomp $url;

    my $agent = WWW::Mechanize->new();
    $agent->get( $url );
    is($agent->status, 200, "Got first page") or diag $agent->res->message;
    is($agent->content, "Referer: ''", "First page gets send with empty referrer");
    is( ref $agent->uri, "", "URI shouldn't be an object" );

    $agent->get( $url );
    is($agent->status, 200, "Got second page") or diag $agent->res->message;
    is($agent->content, "Referer: '$url'", "Referer got sent for absolute url");
    is( ref $agent->uri, "", "URI shouldn't be an object" );
    
    $agent->get( '.' );
    is($agent->status, 200, "Got third page") or diag $agent->res->message;
    is($agent->content, "Referer: '$url'", "Referer got sent for relative url");
    is( ref $agent->uri, "", "URI shouldn't be an object" );

    $WWW::Mechanize::headers{Referer} = '';
    $agent->get( $url );
    is($agent->status, 200, "Got fourth page") or diag $agent->res->message;
    is($agent->content, "Referer: ''", "Referer can be set to empty again");
    is( ref $agent->uri, "", "URI shouldn't be an object" );
    
    my $ref = "This is not the referer you are looking for *jedi gesture*";
    $WWW::Mechanize::headers{Referer} = $ref;
    $agent->get( $url );
    is($agent->status, 200, "Got fourth page") or diag $agent->res->message;
    is($agent->content, "Referer: '$ref'", "Custom referer can be set");
    is( ref $agent->uri, "", "URI shouldn't be an object" );
};

END {
    close SERVER; # boom
};
