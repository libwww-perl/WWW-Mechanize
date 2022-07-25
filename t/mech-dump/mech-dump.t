#!perl -T

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

my $exe = File::Spec->catfile( qw( script mech-dump ) );
if ( $^O eq 'VMS' ) {
    $exe = qq[mcr $^X -Ilib $exe];
}

# Simply use a file: uri instead of the filename to make this test
# more independent of what URI::* thinks.
my $source = 'file:t/google.html t/find_inputs.html t/html_file.txt';

my $perl;
$perl = $1 if $^X =~ /^(.+)$/;
my $command = "$perl -Ilib $exe --forms $source";

my $actual = `$command`;

my $expected;
if ( $LWP::VERSION < 5.800 ) {
    $expected = <<'EOF';
GET file:/target-page [bob-the-form]
  hl=en                           (hidden)
  ie=ISO-8859-1                   (hidden)
  notgoogle=                      (hidden readonly)
  q=
  btnG=Google Search              (submit)
  btnI=I'm Feeling Lucky          (submit)

POST http://localhost/ (multipart/form-data) [1st_form]
  1a=                            (text)
  submit1=Submit                 (image)
  submit2=Submit                 (submit)

POST http://localhost/ [2nd_form]
  YourMom=                       (text)
  opt[2]=                        (text)
  1b=                            (text)
  submit=Submit                  (submit)

POST http://localhost/ [3rd_form]
  YourMom=                       (text)
  YourDad=                       (text)
  YourSister=                    (text)
  YourSister=                    (text)
  submit=Submit                  (submit)

GET http://localhost [text-form]
  one=                           (text)
EOF
} else {
    $expected = <<'EOF';
GET file:/target-page [bob-the-form]
  hl=en                          (hidden readonly)
  ie=ISO-8859-1                  (hidden readonly)
  notgoogle=                     (hidden readonly)
  q=                             (text)
  btnG=Google Search             (submit)
  btnI=I'm Feeling Lucky         (submit)

POST http://localhost/ (multipart/form-data) [1st_form]
  1a=                            (text)
  submit1=Submit                 (image)
  submit2=Submit                 (submit)

POST http://localhost/ [2nd_form]
  YourMom=                       (text)
  opt[2]=                        (text)
  1b=                            (text)
  submit=Submit                  (submit)

POST http://localhost/ [3rd_form]
  YourMom=                       (text)
  YourDad=                       (text)
  YourSister=                    (text)
  YourSister=                    (text)
  submit=Submit                  (submit)

GET http://localhost [text-form]
  one=                           (text)
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

