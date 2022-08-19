#!perl

use warnings;
use strict;

use Test::More;
use Test::Output qw(output_like);
use File::Spec   ();

# See https://stackoverflow.com/a/32054866/1331451
plan skip_all =>
    'capturing output from system() is broken in 5.14 and 5.16 on Windows'
    if $^O eq 'MSWin32' && ( $] >= 5.014 && $] < 5.017 );

plan skip_all => 'Not installing mech-dump'
    if -e File::Spec->catfile(qw( t SKIP-MECH-DUMP ));

my $exe = File::Spec->catfile(qw( script mech-dump ));
if ( $^O eq 'VMS' ) {
  $exe = qq[mcr $^X -Ilib $exe];
}

my $perl;
$perl = $1 if $^X =~ /^(.+)$/;

# The following file should not exist.
my $source = 'file:not_found.404';

my $command = "$perl -Ilib $exe $source";

output_like(
    sub {
        system $command;
    },
    undef,
    qr/file:not_found.404 returns status 404/,
    'Errors when a local file is not found'
);

done_testing;
