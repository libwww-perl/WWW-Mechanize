use warnings;
use strict;
use Test::More tests => 1;
use File::Spec;

local $/ = undef;
my $expected = <DATA>;

my $exe = File::Spec->catfile( qw( blib script mech-forms ) );
my $data = File::Spec->catfile( qw( t google.html ) );
my $actual = `$exe $data`;

is( $actual, $expected );

__DATA__
GET file:/search
  hl=en                           (hidden)  
  ie=ISO-8859-1                   (hidden)  
  q=
  btnG=Google Search              (submit)  
  btnI=I'm Feeling Lucky          (submit)  

