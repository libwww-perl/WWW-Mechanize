package WWW::Mechanize::Link;

=head1 NAME

WWW::Mechanize::Link - link object for Mechanize

=head1 SYNOPSIS

Link object to encapsulate all the stuff that Mech needs but nobody
wants to deal with as an array.

=cut

use strict;
use warnings;

=head1 Constructor

=head2 C<< new( I<$url>, I<$text>, I<$name> ) >>

Creates and returns a new WWW::Mechanize::Link object.

=cut

sub new {
    my $class = shift;

    my $url = shift;
    my $text = shift;
    my $name = shift;
    my $tag = shift;

    my $self = [$url,$text,$name,$tag];

    bless $self, $class;

    return $self;
}

=head2 C<< $link->url() >>

URL from the link

=head2 C<< $link->text() >>

Text of the link

=head2 C<< $link->name() >>

Name from the link tag

For the C<< <A> >> tag, this is the C<HREF> attribute.
For C<< <FRAME> >> or C<< <IFRAME> >>, it's the C<SRC> attribute.

=head2 C<< $link->tag() >>

Tag name (either "a", "frame" or "iframe").

=cut

sub url  { return ($_[0])->[0]; }
sub text { return ($_[0])->[1]; }
sub name { return ($_[0])->[2]; }
sub tag  { return ($_[0])->[3]; }

=head1 Author

Copyright 2003 Andy Lester <andy@petdance.com>

Released under the Artistic License.  Based on Kirrily Robert's excellent
L<WWW::Automate> package.

=cut

1;
