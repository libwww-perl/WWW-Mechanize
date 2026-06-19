use strict;
use warnings;

use Test::More;
use HTTP::Response ();

# A persistent header set via add_header() must not be re-applied to a
# cross-origin redirect target. LWP strips Authorization/Proxy-Authorization
# on cross-origin redirects (the CVE-2018-1000007 mitigation); Mech must not
# put them back via its _modify_request() header loop.
#
# Transport is mocked so LWP's *real* redirect loop runs; only the socket
# layer is replaced. Each request the agent emits is recorded so we can
# inspect the header that reached the redirect target.

{
    package TestMech;
    use parent 'WWW::Mechanize';

    sub simple_request {
        my ( $self, $req ) = @_;
        push @{ $self->{_seen} }, $req;

        my $location = $self->{_route}{ $req->uri->as_string };
        if ($location) {
            my $r = HTTP::Response->new( $self->{_status} || 302 );
            $r->header( Location => $location );
            $r->request($req);
            return $r;
        }
        my $r = HTTP::Response->new(
            200,                             'OK',
            [ 'Content-Type', 'text/html' ], 'ok'
        );
        $r->request($req);
        return $r;
    }
}

my @cases = (
    {
        name     => 'cross-origin redirect strips persistent Authorization',
        header   => 'Authorization',
        value    => 'Basic SECRET',
        start    => 'http://hosta.example/',
        location => 'http://hostb.example/',
        opts     => {},
        expect   => undef,
    },
    {
        name => 'cross-origin redirect strips persistent Proxy-Authorization',
        header   => 'Proxy-Authorization',
        value    => 'Basic SECRET',
        start    => 'http://hosta.example/',
        location => 'http://hostb.example/',
        opts     => {},
        expect   => undef,
    },
    {
        name     => 'same-origin redirect preserves persistent Authorization',
        header   => 'Authorization',
        value    => 'Basic SECRET',
        start    => 'http://hosta.example/one',
        location => 'http://hosta.example/two',
        opts     => {},
        expect   => 'Basic SECRET',
    },
    {
        name =>
            'cross-origin to different port strips persistent Authorization',
        header   => 'Authorization',
        value    => 'Basic SECRET',
        start    => 'http://hosta.example/',
        location => 'http://hosta.example:8080/',
        opts     => {},
        expect   => undef,
    },
    {
        name =>
            'case-only host difference is same-origin and preserves header',
        header   => 'Authorization',
        value    => 'Basic SECRET',
        start    => 'http://hosta.example/',
        location => 'http://HOSTA.example/',
        opts     => {},
        expect   => 'Basic SECRET',
    },
    {
        name     => 'cross-origin redirect strips persistent Cookie',
        header   => 'Cookie',
        value    => 'session=SECRET',
        start    => 'http://hosta.example/',
        location => 'http://hostb.example/',
        opts     => {},
        expect   => undef,
    },
    {
        name     => 'same-origin redirect preserves persistent Cookie',
        header   => 'Cookie',
        value    => 'session=SECRET',
        start    => 'http://hosta.example/one',
        location => 'http://hosta.example/two',
        opts     => {},
        expect   => 'session=SECRET',
    },
    {
        name   => 'allow_credentialed_redirects opts back in to cross-origin',
        header => 'Authorization',
        value  => 'Basic SECRET',
        start  => 'http://hosta.example/',
        location => 'http://hostb.example/',
        opts     => { allow_credentialed_redirects => 1 },
        expect   => 'Basic SECRET',
    },
    {
        name   => 'scheme change (http to https) is cross-origin and strips',
        header => 'Authorization',
        value  => 'Basic SECRET',
        start  => 'http://hosta.example/',
        location => 'https://hosta.example/',
        opts     => {},
        expect   => undef,
    },
    {
        name   => '307 redirect strips persistent Authorization cross-origin',
        header => 'Authorization',
        value  => 'Basic SECRET',
        start  => 'http://hosta.example/',
        location => 'http://hostb.example/',
        status   => 307,
        opts     => {},
        expect   => undef,
    },
    {
        # Same-origin hop preserves the header, then a cross-origin hop strips
        # it: the verdict is made per hop, so a later same-origin target does
        # not get the credential back once an intervening hop has dropped it.
        name   => 'multi-hop redirect strips at the cross-origin hop',
        header => 'Authorization',
        value  => 'Basic SECRET',
        start  => 'http://hosta.example/one',
        route  => {
            'http://hosta.example/one' => 'http://hosta.example/two',
            'http://hosta.example/two' => 'http://hostb.example/',
        },
        final  => 'http://hostb.example/',
        opts   => {},
        expect => undef,
    },
);

for my $case (@cases) {
    subtest $case->{name} => sub {
        my $mech = TestMech->new( autocheck => 0, %{ $case->{opts} } );
        $mech->{_route}
            = $case->{route} || { $case->{start} => $case->{location} };
        $mech->{_status} = $case->{status};
        $mech->add_header( $case->{header} => $case->{value} );

        $mech->get( $case->{start} );

        my @seen = @{ $mech->{_seen} };
        is(
            $seen[0]->header( $case->{header} ),
            $case->{value},
            'first request carries the persistent header',
        );

        my $final = $seen[-1];
        is(
            $final->uri->as_string,
            $case->{final} || $case->{location},
            'final request reached the redirect target',
        );
        is(
            scalar $final->header( $case->{header} ),
            $case->{expect},
            'header on the redirect target is as expected',
        );
    };
}

done_testing;
