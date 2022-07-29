use warnings;
use strict;
use Test::More;

BEGIN { delete @ENV{ qw( http_proxy HTTP_PROXY ) }; }
BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $html = <<'HTML';
<html>
<head>
<title>Test</title>
</head>
<body>
<form name="foo">
<input type="text" name="asdf">
</form>
</body>
</html>
HTML

my $mech = WWW::Mechanize->new();
# Well actually there is no base (and therefore it does not belong to us
# :-), so let's kludge a bit.
$mech->{base} = 'http://example.com/';

$mech->update_html($html);

like( $mech->content, qr/Test/, 'update_html has put the content in' );

is(
    ref( $mech->form_name('foo') ),
    'HTML::Form',
    '... and we now have forms'
);

$html =~ s/foo/bar/;
$mech->update_html($html);

is(
    ref( $mech->form_name('bar') ),
    'HTML::Form',
    'updating the HTML also updates the form'
);


done_testing;