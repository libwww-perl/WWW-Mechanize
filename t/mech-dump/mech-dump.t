#!perl -Tw

use warnings;
use strict;

use Test::More;
use File::Spec;
use LWP;

BEGIN {
    delete @ENV{ qw( IFS CDPATH ENV BASH_ENV PATH ) };
}

plan skip_all => 'Not installing mech-dump' if -e File::Spec->catfile( qw( t SKIP-MECH-DUMP ) );
plan tests => 4;

my $exe = File::Spec->catfile( qw( blib script mech-dump ) );
if ( $^O eq 'VMS' ) {
    $exe = qq[mcr $^X "-mblib" $exe];
}

# Simply use a file: uri instead of the filename to make this test
# more independent of what URI::* thinks.
my $source = 'file:t/google.html';

my $perl;
$perl = $1 if $^X =~ /^(.+)$/;
my $command = "$perl -Mblib $exe --forms $source";

my $actual = `$command`;

my $expected;
if ( $LWP::VERSION < 5.800 ) {
    $expected = <<'EOF';
GET file:/target-page [bob-the-form]
  hl=en                           (hidden)
  ie=ISO-8859-1                   (hidden)
  q=
  btnG=Google Search              (submit)
  btnI=I'm Feeling Lucky          (submit)
EOF
} else {
    $expected = <<'EOF';
GET file:/target-page [bob-the-form]
  hl=en                          (hidden readonly)
  ie=ISO-8859-1                  (hidden readonly)
  q=                             (text)
  btnG=Google Search             (submit)
  btnI=I'm Feeling Lucky         (submit)
EOF
}

my @actual = split /\s*\n/, $actual;
my @expected = split /\s*\n/, $expected;

# First line is platform-dependent, so handle it accordingly.
shift @expected;
my $first = shift @actual;
like( $first, qr/^GET file:.*\/target-page \[bob-the-form\]/, 'First line matches' );

cmp_ok( @expected, '>', 0, 'Still some expected' );
cmp_ok( @actual, '>', 0, 'Still some actual' );

is_deeply( \@actual, \@expected, 'Rest of the lines match' );

