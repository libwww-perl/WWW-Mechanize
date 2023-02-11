use Test::More skip_all =>
    "Mysteriously stopped passing, and I don't know why.";
use warnings;
use strict;
use lib 't/local';
use LocalServer ();
use Test::More tests => 11;

=head1 NAME

overload.t

=head1 SYNOPSIS

This tests for various ways, advertised in L<WWW::Mechanize>, to
create a subclass of the mech to alter it's behavior in a useful
manner. (Of course free-style overloading is discouraged, as it breaks
encapsulation big time.)

This test first feeds some bad HTML to Mech to make sure that it throws
an error.  Then, it overloads update_html() to fix the HTML before
processing it, and then we should not have an error.

=head2 Overloading update_html()

This is the recommended way to tidy up the received HTML in a generic
way, and/or to install supplemental "surface tests" on the HTML
(e.g. link checker).

=cut

BEGIN {
    delete @ENV{qw( IFS CDPATH ENV BASH_ENV )};
    use_ok('WWW::Mechanize');
}

my $server = LocalServer->spawn( html => <<'BROKEN_HTML');
<html>
<head><title>Broken document</head>
<form>
<table>
<tr><select name="foo">
<option value="bar">Bar</option></td></tr>
</form>
</html>
BROKEN_HTML
isa_ok( $server, 'LocalServer' );

do {
    package MyMech;
    use base 'WWW::Mechanize';

    sub update_html {
        my $self = shift;
        my $html = shift;

        $html =~ s[Broken][Fixed]isg
            or die "Couldn't fix the HTML for the test (#1)";
        $html =~ s[</option>.{0,3}</td>][</option></select></td>]isg
            or die "Couldn't fix the HTML for the test (#2)";

        $self->WWW::Mechanize::update_html($html);
    }
};

my $carpmsg;
local $^W = 1;
no warnings 'redefine';
local *Carp::carp = sub { $carpmsg = shift };

my $mech = WWW::Mechanize->new();
isa_ok( $mech, 'WWW::Mechanize' );

$mech->get( $server->url );
like( $carpmsg, qr{bad.*select}i, 'Standard mech chokes on bogus HTML' );

# If at first you don't succeed, try with a shorter bungee...
undef $carpmsg;
$mech = MyMech->new();
isa_ok( $mech, 'WWW::Mechanize', 'Derived object' );

my $response = $mech->get( $server->url );
isa_ok( $response, 'HTTP::Response', 'Response I got back' );
ok( $response->is_success, 'Got URL' ) or die 'Can\'t even fetch local url';
ok( $mech->is_html,        'Local page is HTML' );
ok( !$carpmsg,             'No warnings this time' );

my @forms = $mech->forms;
is( scalar @forms, 1, 'One form' );

like(
    $mech->content(), qr{/select},
    'alteration visible in ->content() too'
);
