use warnings;
use strict;
use lib 't/local';
use LocalServer;
use Test::More tests => 10;

=pod

=head1 NAME

overload.t

=head1 SYNOPSIS

This tests for various ways, advertised in L<WWW::Mechanize>, to
create a subclass of the mech to alter it's behavior in a useful
manner. (Of course free-style overloading is discouraged, as it breaks
encapsulation big time.)

=head2 Overloading update_html()

This is the recommended way to tidy up the received HTML in a generic
way, and/or to install supplemental "surface tests" on the HTML
(e.g. link checker).

=cut

BEGIN { delete @ENV{ qw( http_proxy HTTP_PROXY ) }; }
BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $server = LocalServer->spawn(html => <<'BROKEN_HTML');
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
       my ($self, $html) = @_;
	   $html =~ s[Broken][Fixed]isg;
	   $html =~ s[</option>.?.?.?</td>][</option></select></td>]isg;

	   $self->WWW::Mechanize::update_html( $html );
   }
};

my $carpmsg;
local $^W = 1;
local *Carp::carp = sub {$carpmsg = shift};

my $mech = WWW::Mechanize->new();
do {
	$mech->get ($server->url);
	like($carpmsg, qr/bad.*select/i, "Standard mech chokes on bogus HTML");
};

# If at first you don't succeed, try with a shorter bungee...
undef $carpmsg;
$mech = MyMech->new();
isa_ok( $mech, 'WWW::Mechanize', 'Derived object' );

my $response = $mech->get( $server->url );
isa_ok( $response, 'HTTP::Response', 'Response I got back' );
ok( $response->is_success, 'Got URL' ) or die "Can't even fetch local url";
ok( $mech->is_html, "Local page is HTML" );
ok(! $carpmsg, "No warnings this time");

my @forms = $mech->forms;
is( scalar @forms, 1, "One form" );

like($mech->content(), qr[/select], "alteration visible in ->content() too");
