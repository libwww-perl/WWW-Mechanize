#!perl -Tw

use warnings;
use strict;
use Test::More tests => 5;
use URI::file;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs( 't/find_inputs.html' )->as_string;

$mech->get( $uri );
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};
my $fn = 'headers.tmp';
$mech->dump_headers($fn);
ok( -e $fn );
unlink('headers.tmp');

my $content;
open my $fh, '>', \$content;
$mech->dump_headers( $fh );
like( $content, qr/Content-Length/ );
close $fh;

END {
    unlink('headers.tmp');
}

