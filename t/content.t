use warnings;
use strict;
use lib 't/local';
use LocalServer;
use Test::More tests => 5;

=pod

=head1 NAME

content.t

=head1 SYNOPSIS

Tests the transforming forms of $mech->content().

=cut

BEGIN { delete @ENV{ qw( http_proxy HTTP_PROXY ) }; }
BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $html = <<'HTML';
<html>
<head>
<title>Howdy?</title>
</head>
<body>
Fine, thx!
</body>
</html>
HTML


my $mech = WWW::Mechanize->new();
# Well actually there is no base (and therefore it does not belong to us
# :-), so let's kludge a bit.
$mech->{base} = "http://example.com/";
$mech->update_html($html);

=head2 $mech->content(format => "text")

=cut

SKIP: {
    eval "use HTML::TreeBuilder";
    skip "HTML::TreeBuilder not installed", 2 if $@;

	my $text = $mech->content(format => "text");
	like( $text, qr/Fine/);
	unlike( $text, qr/html/i);
}

=head2 $mech->content(base_href => undef)

=head2 $mech->content(base_href => $basehref)

=cut

my $content = $mech->content(base_href => "foo");
like($content, qr/base href="foo"/);


$content = $mech->content(base_href => undef);
like($content, qr[base href="http://example.com/"]);

