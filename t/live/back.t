use strict;
use Test::More tests => 32;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new();
isa_ok( $mech, "WWW::Mechanize" );

$mech->get( "http://www.google.com/intl/en/" );
ok( $mech->success, 'Fetched OK' ) or die "Can't even get Google";

my $first_base = $mech->base;
my $title = $mech->title;

$mech->follow_link( n=>2 );
ok( $mech->success, 'Followed OK' );

$mech->back();
is( $mech->base, $first_base, "Did the base get set back?" );
is( $mech->title, $title, "Title set back?" );

$mech->follow( "Jobs" );
ok( $mech->success, 'Followed OK' );

$mech->back();
is( $mech->base, $first_base, "Did the base get set back?" );
is( $mech->title, $title, "Title set back?" );

is( scalar @{$mech->{page_stack}}, 0, "Pre-search check" );
$mech->submit_form(
    fields => { q => "perl" },
);
ok( $mech->success, "Searched for Perl" );
like( $mech->title, qr/^Google Search: perl/, "Right page title" );
is( scalar @{$mech->{page_stack}}, 1, "POST is in the stack" );

$mech->head( "http://www.google.com/" );
ok( $mech->success, "HEAD succeeded" );
is( scalar @{$mech->{page_stack}}, 1, "HEAD is not in the stack" );

$mech->back();
ok( $mech->success, "Back" );
is( $mech->base, $first_base, "Did the base get set back?" );
is( $mech->title, $title, "Title set back?" );
is( scalar @{$mech->{page_stack}}, 0, "Post-search check" );


# Now some other weird stuff

my $CPAN = "http://www.cpan.org/";
$mech->get( $CPAN );
ok( $mech->success, 'Got CPAN' );

my @links = qw(
    /scripts
    /ports/
    modules/
);

is( scalar @{$mech->{page_stack}}, 1, "Pre-404 check" );
$mech->get( "/non-existent" );
is( $mech->status, 404 );

is( scalar @{$mech->{page_stack}}, 2, "Even 404s get on the stack" );

$mech->back();
is( $mech->uri, $CPAN, "Back from the 404" );
is( scalar @{$mech->{page_stack}}, 1, "Post-404 check" );

for my $link ( @links ) {
    $mech->get( $link );
    is( $mech->status, 200, "Get $link" );

    $mech->back();
    is( $mech->uri, $CPAN, "Back from $link" );
}

SKIP: {
    eval "use Test::Memory::Cycle";
    skip "Test::Memory::Cycle not installed", 1 if $@;

    memory_cycle_ok( $mech, "No memory cycles found" );
}
