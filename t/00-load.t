#!perl

use warnings;
use strict;
use Test::More tests => 2;

use_ok('WWW::Mechanize');
use_ok('WWW::Mechanize::Link');

diag(
    "Testing WWW::Mechanize $WWW::Mechanize::VERSION, with LWP $LWP::VERSION, Perl $], $^X"
);
