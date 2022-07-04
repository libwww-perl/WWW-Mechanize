#!perl -T

use warnings;
use strict;

use Test::Fatal qw( exception );
use Test::More;
use URI::file;

delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};  # Placates taint-unsafe Cwd.pm in 5.6.1
use_ok( 'WWW::Mechanize' );

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( 't/tick.html' )->as_string;
$mech->get( $uri );
ok( $mech->success, $uri );

$mech->form_number( 1 );
$mech->tick('foo','hello');
$mech->tick('foo','bye');
$mech->untick('foo','hello');

$mech->tick('no_value', '');

my $form = $mech->form_number(1);
isa_ok( $form, 'HTML::Form' );

my $reqstring = $form->click->as_string;

my $wanted = <<'EOT';
POST http://localhost/
Content-Length: 31
Content-Type: application/x-www-form-urlencoded

foo=bye&no_value=&submit=Submit
EOT

is( $reqstring, $wanted, 'Proper posting' );

like(
    exception { $mech->tick( 'not_there', 1 ) },
    qr{No checkbox "not_there" for value "1" in form},
    'dies if checkbox not found'
);

done_testing();
