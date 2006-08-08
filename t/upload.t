#!perl -Tw

use strict;
use Test::More tests => 5;
use URI::file;

BEGIN { delete @ENV{ qw( http_proxy HTTP_PROXY PATH IFS CDPATH ENV BASH_ENV) }; }
use_ok( 'WWW::Mechanize' );

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, "WWW::Mechanize" );

my $uri = URI::file->new_abs( "t/upload.html" )->as_string;
$mech->get( $uri );
ok( $mech->success, $uri );

my $form = $mech->form_number(1);
my $reqstring = $form->click->as_string;
$reqstring =~ s/\r//g;

# trim off possible extra newline
$reqstring =~ s/^\Z\n//m;

my $wanted = <<'EOT';
POST http://localhost/
Content-Length: 77
Content-Type: multipart/form-data; boundary=xYzZY

--xYzZY
Content-Disposition: form-data; name="submit"

Submit
--xYzZY--
EOT

is( $reqstring, $wanted, "Proper posting" );

$mech->field('upload', 'MANIFEST');
$reqstring = $form->click->as_string;
like( $reqstring, qr/Cookbook/, 'The uploaded file should be in the request');

