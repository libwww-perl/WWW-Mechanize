use strict;
use Test::More;

plan tests=>31;

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

is( scalar @{$a->{page_stack}}, 0, "Pre-search check" );
$a->submit_form(
    fields => { q => "perl" },
);
ok( $a->success, "Searched for Perl" );
like( $a->title, qr/^Google Search: perl/, "Right page title" );
is( scalar @{$a->{page_stack}}, 1, "POST is in the stack" );

$a->head( "http://www.google.com/" );
ok( $a->success, "HEAD succeeded" );
is( scalar @{$a->{page_stack}}, 1, "HEAD is not in the stack" );

$a->back();
ok( $a->success, "Back" );
is( $a->base, $first_base, "Did the base get set back?" );
is( $a->title, $title, "Title set back?" );
is( scalar @{$a->{page_stack}}, 0, "Post-search check" );


# Now some other weird stuff

my $CPAN = "http://www.cpan.org/";
$a->get( $CPAN );
ok( $a->success, 'Got CPAN' );

my @links = qw(
    /scripts
    /ports/
    modules/
);

is( scalar @{$a->{page_stack}}, 1, "Pre-404 check" );
$a->get( "/non-existent" );
is( $a->status, 404 );

is( scalar @{$a->{page_stack}}, 2, "Even 404s get on the stack" );

$a->back();
is( $a->uri, $CPAN, "Back from the 404" );
is( scalar @{$a->{page_stack}}, 1, "Post-404 check" );

for my $link ( @links ) {
    $a->get( $link );
    is( $a->status, 200, "Get $link" );

    $a->back();
    is( $a->uri, $CPAN, "Back from $link" );
}
