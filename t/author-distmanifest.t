use strict;
use warnings;

use Test::More;
BEGIN {
    plan skip_all => 'These tests are for authors only!'
        unless -d '.git' || $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING};
}

use Test::DistManifest;
manifest_ok();
