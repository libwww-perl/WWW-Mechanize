use strict;
use Test::More;

plan tests=>16;

use_ok( 'WWW::Mechanize' );

my $a = WWW::Mechanize->new();
isa_ok( $a, "WWW::Mechanize" );

$a->get( "http://www.google.com/intl/en/" );
ok( $a->success, 'Fetched OK' ) or die "Can't even get Google";

my $first_base = $a->base;
my $title = $a->title;

$a->follow_link( n=>2 );
ok( $a->success, 'Followed OK' );

$a->back();
is( $a->base, $first_base, "Did the base get set back?" );
is( $a->title, $title, "Title set back?" );

$a->follow( "Jobs" );
ok( $a->success, 'Followed OK' );

$a->back();
is( $a->base, $first_base, "Did the base get set back?" );
is( $a->title, $title, "Title set back?" );


# Now some other weird stuff

my $CPAN = "http://www.cpan.org/";
$a->get( $CPAN );
ok( $a->success, 'Got CPAN' );

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
