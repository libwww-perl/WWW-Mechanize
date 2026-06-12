#!perl

use warnings;
use strict;

use Test::More;
use WWW::Mechanize ();

BEGIN { delete @ENV{qw( http_proxy HTTP_PROXY )}; }

my $mech = WWW::Mechanize->new( cookie_jar => undef );

# There is no base, so let's kludge a bit.
$mech->{base} = 'http://example.com/';

# Links following an unclosed <a> tag must still be found (GH#212).
my @cases = (
    {
        name => 'single unclosed <a> mid-document',
        html => <<'HTML',
<html>
<head>
<title>Unclosed link mid-document</title>
</head>
<body>
<a href="/1">one
<a href="/2">two</a>
<a href="/3">three</a>
</body>
</html>
HTML
        urls  => [qw( /1 /2 /3 )],
        texts => [qw( one two three )],
    },
    {
        name => 'no closing </a> tags at all',
        html => <<'HTML',
<html>
<head>
<title>No closing tags at all</title>
</head>
<body>
<a href="/first">first
<a href="/second">second
<a href="/third">third
</body>
</html>
HTML
        urls  => [qw( /first /second /third )],
        texts => [qw( first second third )],
    },

    # Nested anchors are invalid HTML, but lock in the stop-at-next-<a>
    # semantics: the outer link's text stops at the inner <a>, and
    # inline markup inside a properly closed link is still flattened
    # into its text.
    {
        name => 'nested anchor and inline markup',
        html => <<'HTML',
<html>
<head>
<title>Nested anchor and inline markup</title>
</head>
<body>
<a href="/outer">before <a href="/inner">inner</a>
<a href="/bold"><b>bold</b> text</a>
</body>
</html>
HTML
        urls  => [qw( /outer /inner /bold )],
        texts => [ 'before', 'inner', 'bold text' ],
    },
);

for my $case (@cases) {
    subtest $case->{name} => sub {
        $mech->update_html( $case->{html} );

        my @links = $mech->find_all_links();
        is(
            scalar @links,
            scalar @{ $case->{urls} },
            'All links found'
        );
        is_deeply(
            [ map { $_->url } @links ],
            $case->{urls},
            'Links have the expected URLs'
        );
        is_deeply(
            [ map { $_->text } @links ],
            $case->{texts},
            'Each link keeps only its own text'
        );
    };
}

done_testing();
