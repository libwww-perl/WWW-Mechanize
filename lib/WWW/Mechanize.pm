package WWW::Mechanize;

=head1 NAME

WWW::Mechanize - automate interaction with websites

=head1 SYNOPSIS

    use WWW::Mechanize;
    my $agent = WWW::Mechanize->new();

    $agent->get($url);

    $agent->follow($link);

    $agent->form($number);
    $agent->field($name, $value);
    $agent->click($button);

    $agent->back();

    $agent->add_header($name => $value);

    use Test::More;
    like( $agent->{content}, qr/$expected/, "Got expected content" );

=head1 DESCRIPTION

This module is intended to help you automate interaction with a website.
It bears a not-very-remarkable outwards resemblance to WWW::Chat, on which
it is based.  The main difference between this module and WWW::Chat is
that WWW::Chat requires a pre-processing stage before you can run your
script, whereas WWW::Mechanize does not.

WWW::Mechanize is a subclass of LWP::UserAgent, so anything you can do
with an LWP::UserAgent, you can also do with this.  See L<LWP::UserAgent>
for more information on the possibilities.

=cut

use strict;
use warnings;

use HTTP::Request;
use LWP::UserAgent;
use HTML::Form;
use HTML::TokeParser;
use Clone qw(clone);
use Carp;
use URI::URL;

our @ISA = qw( LWP::UserAgent );

=head1 VERSION

Version 0.32

    $Header: /home/cvs/www-mechanize/lib/WWW/Mechanize.pm,v 1.20 2002/10/24 04:12:42 alester Exp $

=cut

our $VERSION = "0.32";

our %headers;

=head1 METHODS

=head2 new()

Creates and returns a new WWW::Mechanize object, hereafter referred to as
the 'agent'.

    my $agent = WWW::Mechanize->new()

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new( @_ );

    $self->{page_stack} = [];
    $self->agent( "WWW-Mechanize/$VERSION" );
    $self->env_proxy();

    return bless $self, $class;
}


=head2 $agent->get($url)

Given a URL/URI, fetches it.  Returns an HTTP::Response object.

The results are stored internally in the agent object, as follows:

     uri       The current URI
     req       The current request object        [HTTP::Request]
     res       The response received             [HTTP::Response]
     status    The status code of the response
     ct        The content type of the response
     base      The base URI for current response
     content   The content of the response
     forms     Array of forms found in content   [HTML::Form]
     form      Current form                      [HTML::Form]
     links     Array of links found in content 

You can get at them with, for example: C<< $agent->{content} >>

=cut

sub get {
    my ($self, $uri) = @_;

    if ( $self->{base} ) {
	$self->{uri} = URI->new_abs( $uri, $self->{base} );
    } else {
	$self->{uri} = URI->new( $uri );
    }

    $self->{req} = HTTP::Request->new( GET => $self->{uri} );

    return $self->_do_request(); 
}

=head2 $agent->follow($string|$num)

Follow a link.  If you provide a string, the first link whose text 
matches that string will be followed.  If you provide a number, it will 
be the nth link on the page.

=cut

sub follow {
    my ($self, $link) = @_;
    my @links = @{$self->{links}};
    my $thislink;
    if ( $link =~ /^\d+$/ ) { # is a number?
        if ($link <= $#links) {
            $thislink = $links[$link];
        } else {
            warn "Link number $link is greater than maximum link $#links ",
                 "on this page ($self->{uri})\n";
            return undef;
        }
    } else {                        # user provided a regexp
        LINK: foreach my $l (@links) {
            if ($l->[1] =~ /$link/) {
                $thislink = $l;     # grab first match
                last LINK;
            }
        }
        unless ($thislink) {
            warn "Can't find any link matching $link on this page ",
                 "($self->{uri})\n";
            return undef;
        }
    }

    $thislink = $thislink->[0];     # we just want the URL, not the text

    $self->_push_page_stack();
    $self->get( $thislink );

    return 1;
}

=head2 $agent->form($number)

Selects the Nth form on the page as the target for subsequent calls to
field() and click().  Emits a warning and returns false if there is no
such form.  Forms are indexed from 1, that is to say, the first form is
number 1 (not zero).

=cut

sub form {
    my ($self, $form) = @_;
    if ($self->{forms}->[$form-1]) {
        $self->{form} = $self->{forms}->[$form-1];
        return 1;
    } else {
        carp "There is no form number $form";
        return 0;
    }
}

=head2 $agent->field($name, $value, $number)

Given the name of a field, set its value to the value specified.  This
applies to the current form (as set by the form() method or defaulting
to the first form on the page).

The optional $number parameter is used to distinguish between two fields
with the same name.  The fields are numbered from 1.

=cut

sub field {
    my ($self, $name, $value, $number) = @_;
    $number ||= 1;

    my $form = $self->{form};
    if ($number > 1) {
	$form->find_input($name, $number)->value($value);
    } else {
        $form->value($name => $value);
    }
}

=head2 $agent->click($button, $x, $y);

Has the effect of clicking a button on a form.  The first argument
is the name of the button to be clicked.  The second and third
arguments (optional) allow you to specify the (x,y) cooridinates
of the click.

If there is only one button on the form, C<< $agent->click() >> with
no arguments simply clicks that one button.

Returns an HTTP status code.

=cut

sub click {
    my ($self, $button, $x, $y) = @_;
    for ($x, $y) { $_ = 1 unless defined; }
    $self->_push_page_stack();
    $self->{uri} = $self->{form}->uri;
    $self->{req} = $self->{form}->click($button, $x, $y);
    return $self->_do_request();
}

=head2 $agent->submit()

Shortcut for $a->click("submit")

=cut

sub submit {
    my ($self) = shift;
    return $self->click("submit");
}

=head2 $agent->back();

The equivalent of hitting the "back" button in a browser.  Returns to
the previous page.  Won't go back past the first page.

=cut

sub back {
    my $self = shift;
    $self->_pop_page_stack;
}

=head2 $agent->add_header(name => $value)

Sets a header for the WWW::Mechanize agent to use every time it gets a
webpage.  This is B<NOT> stored in the agent object (because if it were,
it would disappear if you went back() past where you'd set it) but in
the hash variable %WWW::Mechanize::headers, which is a hash of all headers
to be set.  You can manipulate this directly if you want to; the
add_header() method is just provided as a convenience function for the most
common case of adding a header.

=cut

sub add_header {
    my ($self, $name, $value) = @_;
    $WWW::Mechanize::headers{$name} = $value;
}

=head2 extract_links()

Extracts HREF links from the content of a webpage.

The return value is a reference to an array containing
an array reference for every C<< <A> >> and C<< <FRAME> >>
tag in C<$self->{content}>.  

The array elements for the C<< <A> >> tag are:

=over 4

=item [0]: the contents of the C<href> attribute

=item [1]: the text enclosed by the C<< <A> >> tag

=item [2]: the contents of the C<name> attribute

=back

The array elements for the C<< <FRAME> >> tag are:

=over 4

=item [0]: the contents of the C<src> attribute

=item [1]: the contents of the C<name> attribute

=item [2]: the contents of the C<name> attribute

=back

=cut

sub extract_links {
    my $self = shift;
    my $p = HTML::TokeParser->new(\$self->{content});
    my @links;

    while (my $token = $p->get_tag("a", "frame")) {
	my $tag_is_a = ($token->[0] eq 'a');
	my $url = $tag_is_a ? $token->[1]{href} : $token->[1]{src};
	next unless defined $url;   # probably just a name link

	my $text = $tag_is_a ? $p->get_trimmed_text("/a") : $token->[1]{name};
	my $name = $token->[1]{name};
	push(@links, [$url, $text, $name]);
    }
    return \@links;
}

=head1 INTERNAL METHODS

These methods are only used internally.  You probably don't need to 
know about them.

=head2 _push_page_stack() / _pop_page_stack()

The agent keeps a stack of visited pages, which it can pop when it needs
to go BACK and so on.  

The current page needs to be pushed onto the stack before we get a new
page, and the stack needs to be popped when BACK occurs.

Neither of these take any arguments, they just operate on the $agent
object.

=cut

sub _push_page_stack {
    my $self = shift;

    my $save_stack = $self->{page_stack};
    $self->{page_stack} = [];

    push( @$save_stack, clone($self) );

    $self->{page_stack} = $save_stack;

    return 1;
}

sub _pop_page_stack {
    my $self = shift;

    if (@{$self->{page_stack}}) {
	my $popped = pop @{$self->{page_stack}};

	# eliminate everything in self
	foreach my $key ( keys %$self ) {
	    delete $self->{ $key }		unless $key eq 'page_stack';
	}

	# make self just like the popped object
	foreach my $key ( keys %$popped ) {
	    $self->{ $key } = $popped->{ $key } unless $key eq 'page_stack';
	}
    }

    return 1;
}


=head2 _do_request()

Performs a request on the $self->{req} request object, and sets
a bunch of attributes on $self.

Returns an L<HTTP::Response> object.

=cut

sub _do_request {
    my ($self) = @_;
    foreach my $h (keys %WWW::Mechanize::headers) {
        $self->{req}->header( $h => $WWW::Mechanize::headers{$h} );
    }
    $self->{res}     = $self->request($self->{req});
    $self->{status}  = $self->{res}->code;
    $self->{base}    = $self->{res}->base;
    $self->{ct}      = $self->{res}->content_type || "";
    $self->{content} = $self->{res}->content;

    if ($self->{ct} eq 'text/html') {
        $self->{forms} = [ HTML::Form->parse($self->{content}, $self->{res}->base) ];
        $self->{form}  = $self->{forms}->[0] if @{$self->{forms}};
        $self->{links} = $self->extract_links();
    }

    return $self->{res};
}

=head1 BUGS

Please report any bugs via the system at http://rt.cpan.org/, or email to
bug-WWW-Mechanize@rt.cpan.org.

=head1 AUTHOR

Copyright 2002 Andy Lester <andy@petdance.com>

Released under the Artistic License.  Based on Kirrily Robert's excellent
L<WWW::Automate> package.

=cut

1;
