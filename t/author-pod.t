#!perl -T

use warnings;
use strict;
use Test::More;

BEGIN {
    plan skip_all => 'These tests are for authors only!'
        unless $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING};
}

use Test::Pod 1.14;
all_pod_files_ok();
