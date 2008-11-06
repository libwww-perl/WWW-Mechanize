#!perl

use warnings;
use strict;
use Test::More tests => 38;
use lib 't/local';
use LocalServer;
use HTTP::Daemon;
use HTTP::Response;


=head1 NAME

=head1 SYNOPSIS

This tests Mech's Back "button". Tests were converted from t/live/back.t,
and subsequently enriched to deal with RT ticket #8109.

=cut

BEGIN {
    delete @ENV{ grep { lc eq 'http_proxy' } keys %ENV };
    delete @ENV{ qw( IFS CDPATH ENV BASH_ENV ) };
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new(cookie_jar => {});
isa_ok( $mech, 'WWW::Mechanize' );
isa_ok( $mech->cookie_jar(), 'HTTP::Cookies', 'this $mech starts with a cookie jar' );

my $html = <<'HTML';
<html>
<head><title>%s</title></head>
<body>Whatever.
<a href="images/">Images</a>
<a href="/scripts">Scripts</a>
<a href="/ports/">Ports</a>
<a href="modules/">Modules</a>
<form action="/search.cgi">
<input type="text" name="q">
<input type="submit">
</form>
</body>
</html>
HTML

my $server = LocalServer->spawn( html => $html );
isa_ok( $server, 'LocalServer' );

$mech->get($server->url);
ok( $mech->success, 'Fetched OK' );

my $first_base = $mech->base;
my $title = $mech->title;

$mech->follow_link( n=>2 );
ok( $mech->success, 'Followed OK' );

$mech->back();
is( $mech->base, $first_base, 'Did the base get set back?' );
is( $mech->title, $title, 'Title set back?' );

$mech->follow_link( text => 'Images' );
ok( $mech->success, 'Followed OK' );

$mech->back();
is( $mech->base, $first_base, 'Did the base get set back?' );
is( $mech->title, $title, 'Title set back?' );

is( scalar @{$mech->{page_stack}}, 0, 'Pre-search check' );
$mech->submit_form(
    fields => { 'q' => 'perl' },
);
ok( $mech->success, 'Searched for Perl' );
like( $mech->title, qr/search.cgi/, 'Right page title' );
is( scalar @{$mech->{page_stack}}, 1, 'POST is in the stack' );

$mech->head( $server->url );
ok( $mech->success, 'HEAD succeeded' );
is( scalar @{$mech->{page_stack}}, 1, 'HEAD is not in the stack' );

$mech->back();
ok( $mech->success, 'Back' );
is( $mech->base, $first_base, 'Did the base get set back?' );
is( $mech->title, $title, 'Title set back?' );
is( scalar @{$mech->{page_stack}}, 0, 'Post-search check' );

=head2 Back and misc. internal fields

RT ticket #8109 reported that back() is broken after reload(), and
that the cookie_jar was also damaged by back(). We test for that:
reload() should not alter the back() stack, and the cookie jar should
not be versioned (once a cookie is set, hitting the back button in a
browser does not cause it to go away).

=cut

$mech->follow_link( text => 'Images' );
$mech->reload();
$mech->back();
is($mech->title, $title, 'reload() does not push page to stack' );

ok(defined($mech->cookie_jar()),
   '$mech still has a cookie jar after a number of back()');

# Now some other weird stuff. Start with a fresh history by recreating
# $mech.
SKIP: {
    eval 'use Test::Memory::Cycle';
    skip 'Test::Memory::Cycle not installed', 1 if $@;

    memory_cycle_ok( $mech, 'No memory cycles found' );
}

$mech = WWW::Mechanize->new( autocheck => 0 );
isa_ok( $mech, 'WWW::Mechanize' );
$mech->get( $server->url );
ok( $mech->success, 'Got root URL' );

my @links = qw(
    /scripts
    /ports/
    modules/
);

is( scalar @{$mech->{page_stack}}, 0, 'Pre-404 check' );

my $server404 = HTTP::Daemon->new(LocalAddr => 'localhost') or die;
my $server404url = $server404->url;

die 'Cannot fork' if (! defined (my $pid404 = fork()));
END {
    local $?;
    kill KILL => $pid404; # Extreme prejudice intended, because we do not
    # want the global cleanup to be done twice.
}

if (! $pid404) { # Fake HTTP server code: a true 404-compliant server!
    while ( my $c = $server404->accept() ) {
        while ( $c->get_request() ) {
            $c->send_response( new HTTP::Response(404) );
            $c->close();
        }
    }
}

$mech->get($server404url);
is( $mech->status, 404 , '404 check') or
    diag( qq{\$server404url=$server404url\n\$mech->content="}, $mech->content, qq{"\n} );

is( scalar @{$mech->{page_stack}}, 1, 'Even 404s get on the stack' );

$mech->back();
is( $mech->uri, $server->url, 'Back from the 404' );
is( scalar @{$mech->{page_stack}}, 0, 'Post-404 check' );

for my $link ( @links ) {
    $mech->get( $link );
    warn $mech->status() if (! $mech->success());
    is( $mech->status, 200, "Get $link" );

    $mech->back();
    is( $mech->uri, $server->url, "Back from $link" );
}

SKIP: {
    eval 'use Test::Memory::Cycle';
    skip 'Test::Memory::Cycle not installed', 1 if $@;

    memory_cycle_ok( $mech, 'No memory cycles found' );
}


