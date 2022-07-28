#!perl

use warnings;
use strict;
use Test::More tests => 2;

=head1 NAME

bad-request.t

=head1 SYNOPSIS

Tests the detection of bad API usage.

  ->request()

Checks for behaviour of calls to C<< ->request() >> without the required
parameter.

=cut

use WWW::Mechanize ();

my $mech = WWW::Mechanize->new();

my $lives= eval {
#line 1
    $mech->request();
    1
};
my $err= $@;
ok !$lives, "->request wants at least one parameter";
like $err, qr/->request was called without a request parameter/,
    "We carp with a descriptive error message";

