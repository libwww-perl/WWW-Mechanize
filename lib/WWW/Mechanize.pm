package WWW::Mechanize;

=head1 NAME

WWW::Mechanize - automate interaction with websites

=head1 SYNOPSIS

    use WWW::Mechanize;
    my $agent = WWW::Mechanize->new();

    $agent->get($url);

    $agent->follow($link);

    $agent->form_number($number);
    $agent->form_name($name);
    $agent->field($name, $value);
    $agent->click($button);

    $agent->back();

    $agent->add_header($name => $value);

    use Test::More;
    like( $agent->{content}, qr/$expected/, "Got expected content" );

=head1 DESCRIPTION

This module is intended to help you automate interaction with a website.
It bears a not-very-remarkable outwards resemblance to L<WWW::Chat>, on which
it is based.  The main difference between this module and WWW::Chat is
that WWW::Chat requires a pre-processing stage before you can run your
script, whereas WWW::Mechanize does not.

=cut

use strict;
use warnings;

use HTTP::Request;
use LWP::UserAgent;
use HTML::Form;
use HTML::TokeParser;
use Carp;
use URI::URL;

our @ISA = qw( LWP::UserAgent );

=head1 VERSION

Version 0.37

    $Header: /home/cvs/www-mechanize/lib/WWW/Mechanize.pm,v 1.39 2003/03/04 21:04:11 alester Exp $

=cut

our $VERSION = "0.37";

our %headers;

=head1 METHODS

=head2 new()

Creates and returns a new WWW::Mechanize object, hereafter referred to as
the 'agent'.

    my $agent = WWW::Mechanize->new()

The constructor for WWW::Mechanize overrides two of the parms to the
LWP::UserAgent constructor:

    agent => "WWW::Mechanize/#.##" cookie_jar => {}    # an empty,
    memory-only HTTP::Cookies object

You can override these overrides by passing parms to the constructor,
as in:

    my $agent = WWW::Mechanize->new( agent=>"wonderbot 1.01" );

If you want none of the overhead of a cookie jar, or don't want your
bot accepting cookies, you have to explicitly disallow it, like so:

    my $agent = WWW::Mechanize->new( cookie_jar => undef );

=cut

sub new {
    my $class = shift;

    my %default_parms = (
	agent	    => "WWW-Mechanize/$VERSION",
	cookie_jar  => {},
    );

    my $self = $class->SUPER::new( %default_parms, @_ );

    $self->{page_stack} = [];
    $self->{quiet} = 0;
    $self->env_proxy();

    return bless $self, $class;
}


=head2 $agent->get($url)

Given a URL/URI, fetches it.  Returns an HTTP::Response object.

The results are stored internally in the agent object, but you don't
know that.  Just use the accessors listed below.  Poking at the internals
is deprecated and subject to change in the future.

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

=head2 $agent->uri()

Returns the current URI.

=head2 $agent->req()

Returns the current request as an C<HTTP::Request> object.

=head2 $agent->res()

Returns the current response as an C<HTTP::Response> object.

=head2 $agent->status()

Returns the HTTP status code of the response.

=head2 $agent->ct()

Returns the content type of the response.

=head2 $agent->base()

Returns the base URI for the current response

=head2 $agent->content()

Returns the content for the response

=head2 $agent->forms()

Returns an array of C<HTML::Form> objects for the forms found.

=head2 $agent->current_form()

Returns the current form as an C<HTML::Form> object.  I'd call this
C<form()> except that C<form()> already exists and sets the current_form.

=head2 $agent->links()

Returns an arrayref of the links found

=head2 $agent->is_html()

Returns true/false on whether our content is HTML, according to the
HTTP headers.

=cut

sub uri {	    my $self = shift; return $self->{uri}; }
sub req {	    my $self = shift; return $self->{req}; }
sub res {	    my $self = shift; return $self->{res}; }
sub status {	    my $self = shift; return $self->{status}; }
sub ct {	    my $self = shift; return $self->{ct}; }
sub base {	    my $self = shift; return $self->{base}; }
sub content {	    my $self = shift; return $self->{content}; }
sub current_form {  my $self = shift; return $self->{form}; }
sub forms {	    my $self = shift; return $self->{forms}; }
sub links {	    my $self = shift; return $self->{links}; }
sub is_html {	    my $self = shift; return $self->{ct} eq "text/html"; }

=head2 $agent->title()

Returns the contents of the C<< <TITLE> >> tag, as parsed by
HTML::HeadParser.  Returns undef if the content is not HTML.

=cut

sub title {
    my $self = shift;
    return undef unless $self->is_html;

    require HTML::HeadParser;
    my $p = HTML::HeadParser->new;
    $p->parse($self->content);
    return $p->header('Title');
}

=head1 Action methods

=head2 $agent->follow($string|$num)

Follow a link.  If you provide a string, the first link whose text 
matches that string will be followed.  If you provide a number, it will 
be the nth link on the page.

Returns true if the link was found on the page or undef otherwise.

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
                 "on this page ($self->{uri})\n" unless $self->quiet;
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
                 "($self->{uri})\n" unless $self->quiet;
            return undef;
        }
    }

    $thislink = $thislink->[0];     # we just want the URL, not the text

    $self->_push_page_stack();
    $self->get( $thislink );

    return 1;
}

=head2 $agent->quiet(true/false)

Allows you to suppress warnings to the screen.

    $agent->quiet(0); # turns on warnings (the default)
    $agent->quiet(1); # turns off warnings
    $agent->quiet();  # returns the current quietness status

=cut

sub quiet {
    my $self = shift;

    $self->{quiet} = $_[0] if @_;

    return $self->{quiet};
}

=head2 $agent->form($number|$name)

Selects a form by number or name, depending on if it gets passed an
all-numeric string or not.  If you have a form with a name that is all
digits, you'll need to call C< $agent->form_name > explicitly.

=cut

sub form {
    my $self = shift;
    my $arg = shift;

    return $arg =~ /^\d+$/ ? $self->form_number($arg) : $self->form_name($arg);
}

=head2 $agent->form_number($number)

Selects the Nth form on the page as the target for subsequent calls to
field() and click().  Emits a warning and returns false if there is no
such form.  Forms are indexed from 1, that is to say, the first form is
number 1 (not zero).

=cut

sub form_number {
    my ($self, $form) = @_;
    if ($self->{forms}->[$form-1]) {
        $self->{form} = $self->{forms}->[$form-1];
        return 1;
    } else {
        carp "There is no form number $form" unless $self->quiet;
        return 0;
    }
}

=head2 $agent->form_name($number)

Selects a form by name.  If there is more than one form on the page with
that name, then the first one is used, and a warning is generated.

Note that this functionality requires libwww-perl 5.69 or higher.

=cut

sub form_name {
    my ($self, $form) = @_;

    my $temp;
    my @matches = grep {defined($temp = $_->attr('name')) and ($temp eq $form) } @{$self->{forms}};
    if ( @matches ) {
	$self->{form} = $matches[0];
	warn "There are ", scalar @matches, " forms named $form.  The first one was used."
	    if @matches > 1 && !$self->{quiet};
        return 1;
    } else {
        carp "There is no form named $form" unless $self->{quiet};
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

Returns an HTTP::Response object.

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

=item [0]: contents of the C<href> attribute

=item [1]: text enclosed by the C<< <A> >> tag

=item [2]: the contents of the C<name> attribute

=back

The array elements for the C<< <FRAME> >> tag are:

=over 4

=item [0]: contents of the C<src> attribute

=item [1]: text enclosed by the C<< <FRAME> >> tag

=item [2]: contents of the C<name> attribute

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

    push( @$save_stack, $self->clone );

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

    # These internal hash elements should be dropped in favor of
    # the accessors soon. -- 1/19/03
    $self->{status}  = $self->{res}->code;
    $self->{base}    = $self->{res}->base;
    $self->{ct}      = $self->{res}->content_type || "";
    $self->{content} = $self->{res}->content;

    if ( $self->is_html ) {
        $self->{forms} = [ HTML::Form->parse($self->{content}, $self->{res}->base) ];
        $self->{form}  = @{$self->{forms}} ? $self->{forms}->[0] : undef;
        $self->{links} = $self->extract_links();
    }

    return $self->{res};
}

=head1 EXAMPLES

Following are user-supplied samples of WWW::Mechanize in action.  If you
have samples you'd like to contribute, please send 'em.

You can also look at the F<t/*.t> files in the distribution.

=head2 get-despair

Randal Schwartz submitted this bot that walks the despair.com site
sucking down all the pictures.

    use strict; 
    $|++;
     
    use WWW::Mechanize;
    use File::Basename; 
      
    my $m = WWW::Mechanize->new;
     
    $m->get("http://www.despair.com/indem.html");
     
    my @top_links = @{$m->links};
      
    for my $top_link_num (0..$#top_links) {
	next unless $top_links[$top_link_num][0] =~ /^http:/; 
	 
	$m->follow($top_link_num) or die "can't follow $top_link_num";
	 
	print $m->uri, "\n";
	for my $image (grep m{^http://store4}, map $_->[0], @{$m->links}) { 
	    my $local = basename $image;
	    print " $image...", $m->mirror($image, $local)->message, "\n"
	}
	 
	$m->back or die "can't go back";
    }

=head1 REQUESTS & BUGS

Please report any requests, suggestions or (gasp!) bugs via the system
at http://rt.cpan.org/, or email to bug-WWW-Mechanize@rt.cpan.org.
This makes it much easier for me to track things.

=head1 AUTHOR

Copyright 2002 Andy Lester <andy@petdance.com>

Released under the Artistic License.  Based on Kirrily Robert's excellent
L<WWW::Automate> package.

=cut

1;
