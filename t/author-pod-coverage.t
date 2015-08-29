#!perl -T

use warnings;
use strict;
use Test::More;

BEGIN {
    plan skip_all => 'These tests are for authors only!'
        unless -d '.git' || $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING};
}

use Test::Pod::Coverage 1.04;
all_pod_coverage_ok();
