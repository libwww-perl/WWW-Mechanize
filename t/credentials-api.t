#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use LWP::UserAgent;
use WWW::Mechanize;

=pod

The monkeypatch introduced since at least WWW::Mechanize 1.34 only
ever allows one instance of every LWP::UserAgent descendant to have
credentials.  This test checks that this buggy behaviour is gone.

=cut

my $ua = LWP::UserAgent->new();
my $m_1 = WWW::Mechanize->new();
my $m_2 = WWW::Mechanize->new();
my $m_3 = WWW::Mechanize->new();

$m_1->credentials('m_1','m_1');
$m_2->credentials('m_2','m_2');

my @ua = $ua->credentials;
isnt( "@ua", "m_2 m_2", 'LWP::UserAgent instance retains its old credentials' );

is_deeply [$m_1->get_basic_credentials], ['m_1','m_1'], 'First instance retains its credentials';
is_deeply [$m_2->get_basic_credentials], ['m_2','m_2'], 'Second instance retains its credentials';
is_deeply [$m_3->get_basic_credentials], [undef,undef], 'Untouched instance retains its credentials';
