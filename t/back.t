use strict;
use Test::More tests=>16;

use_ok( 'WWW::Mechanize' );

my $a = WWW::Mechanize->new();
isa_ok( $a, "WWW::Mechanize" ) or die;

$a->get( "http://www.google.com/intl/en/" );
is( $a->status, 200, 'Fetched OK' );

my $first_base = $a->base;
my $title = $a->title;

$a->follow( 2 );
is( $a->status, 200, 'Followed OK' );

$a->back();
is( $a->base, $first_base, "Did the base get set back?" );
is( $a->title, $title, "Title set back?" );

$a->follow( "Jobs" );
is( $a->status, 200, 'Followed OK' );

$a->back();
is( $a->base, $first_base, "Did the base get set back?" );
is( $a->title, $title, "Title set back?" );


# Now some other weird stuff
#

my $CPAN = "http://www.cpan.org/";
$a->get( $CPAN );
is( $a->status, 200 );

TODO: {
    local $TODO = "Still have to get the back() stuff working";

    my @links = qw(
	/scripts
	/ports/
	modules/
    );

    for my $link ( @links ) {
	$a->get( $link );
	is( $a->status, 200 );

	$a->back();
	is( $a->uri, $CPAN );
    }
}
