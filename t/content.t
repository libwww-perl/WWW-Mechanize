use warnings;
use strict;
use Test::More;
use Test::Exception;

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
$mech->{base} = 'http://example.com/';

is($mech->content, undef, 'content starts out as undef');

$mech->update_html($html);

=head2 $mech->content(format => "text")

=cut

SKIP: {
    eval 'use HTML::TreeBuilder 5';
    skip 'HTML::TreeBuilder version 5 not installed', 2 if $@;

    my $text = $mech->content(format => 'text');
    like( $text, qr/Fine/, 'Found Fine' );
    unlike( $text, qr/html/i, 'Could not find "html"' );
}

dies_ok { $mech->content(format => 'no_such_format' ) } 'Unkown format';

=head2 $mech->content(base_href => undef)

=head2 $mech->content(base_href => $basehref)

=cut

my $content = $mech->content(base_href => 'foo');
like($content, qr/base href="foo"/, 'Found the base href');


$content = $mech->content(base_href => undef);
like($content, qr[base href="http://example.com/"], 'Found the new base href');

$mech->{res} = Test::MockResponse->new(
   raw_content => 'this is the raw content',
   charset_none => 'this is a slightly decoded content',
   charset_whatever => 'this is charset whatever',
);

$content = $mech->content(raw => 1);
is($content, 'this is the raw content', 'raw => 1');

$content = $mech->content(decoded_by_headers => 1);
is($content, 'this is a slightly decoded content', 'decoded_by_headers => 1');

$content = $mech->content(charset => 'whatever');
is($content, 'this is charset whatever', 'charset => ...');

dies_ok { $mech->content(unhandled => 'param') } 'unhandled param';

done_testing;

package Test::MockResponse;

sub new {
   my $package = shift;
   return bless { @_ }, $package;
}

sub content {
   my ($self) = @_;
   return $self->{raw_content};
}

sub decoded_content {
   my ($self, %opts) = @_;
   return $self->{decoded_content} unless exists $opts{charset};
   return $self->{"charset_$opts{charset}"};
}
