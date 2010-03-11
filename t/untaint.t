#!/usr/bin/perl

use strict;
use warnings;
use URI::file;

use Test::More;

eval 'use Test::NoWarnings';
if ( $@ ) {
    plan( skip_all => 'Test::NoWarnings not installed' );
}

plan( tests => 2 ); # the use_ok and then the warning check
$ENV{test} = undef;
use_ok( 'WWW::Mechanize' );
my $uri = URI::file->new_abs( 't/find_link_id.html' )->as_string;
WWW::Mechanize->new->get($uri);
