use warnings;
use strict;
use Test::More;
use File::Spec;
use URI::file;

local $/ = undef;

my $exe = File::Spec->catfile( qw( blib script mech-forms ) );
plan skip_all => "Not installing mech-forms" if -e "t/SKIP-MECH-FORMS";
plan tests=>1;

my $data = File::Spec->catfile( qw( t google.html ) );
my $actual = `$exe $data`;

my $target = URI->new_abs( "/target-page", $data );
$target = URI::file->new_abs( $target )->as_string;

my $expected = <DATA>;
$expected =~ s/#TARGET#/$target/;
is( $actual, $expected );

__DATA__
GET #TARGET#
  hl=en                           (hidden)  
  ie=ISO-8859-1                   (hidden)  
  q=
  btnG=Google Search              (submit)  
  btnI=I'm Feeling Lucky          (submit)  

