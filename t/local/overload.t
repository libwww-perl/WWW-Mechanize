use warnings;
use strict;
use lib 't/local';
use LocalServer ();
use Test::More;

# Tests the advertised way to subclass mech to alter its behavior:
# overloading update_html() to tidy up the received HTML before
# processing (e.g. fixing broken markup or installing surface tests).
# Here we feed deliberately-broken HTML and confirm the overload repairs
# it so the form parses cleanly and without warnings.

BEGIN {
    delete @ENV{qw( IFS CDPATH ENV BASH_ENV )};
    use_ok('WWW::Mechanize');
}

my $server = LocalServer->spawn( html => <<'BROKEN_HTML' );
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
    use parent 'WWW::Mechanize';

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
local $^W = 1;   # enable all warnings so the carp-capture below is meaningful
no warnings 'redefine';
local *Carp::carp = sub { $carpmsg = shift };

my $mech = MyMech->new();
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

done_testing;
