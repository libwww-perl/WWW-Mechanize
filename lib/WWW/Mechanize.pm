package WWW::Mechanize;

=head1 NAME

WWW::Mechanize - automate interaction with websites

=head1 VERSION

Version 0.46

    $Header: /cvsroot/www-mechanize/www-mechanize/lib/WWW/Mechanize.pm,v 1.9 2003/06/22 03:18:15 petdance Exp $

=cut

our $VERSION = "0.46";

=head1 SYNOPSIS

C<WWW::Mechanize>, or Mech for short, was designed to help you
automate interaction with a website. It supports performing a
sequence of page fetches including following links and submitting
forms. Each fetched page is parsed and its links and forms are
extracted. A link or a form can be selected, form fields can be
filled and the next page can be fetched. Mech also stores a history
of the URLs you've visited, which can be queried and revisited.

    use WWW::Mechanize;
    my $a = WWW::Mechanize->new();

    $a->get($url);

    $a->follow_link( n => 3 );
    $a->follow_link( text_regex => qr/download this/i );
    $a->follow_link( url => 'http://host.com/index.html' );

    $a->submit_form(
	form_number => 3,
	fields      => {
			username    => 'yourname',
			password    => 'dummy',
			}
    );

    $a->submit_form(
	form_name => 'search',
	fields    => { query  => 'pot of gold', },
	button    => 'Search Now'
    );


Mech is well suited for use in testing web applications.  If you
use one of the Test::* modules, you can check the fetched content
and use that as input to a test call.

    use Test::More;
    like( $a->content(), qr/$expected/, "Got expected content" );

Each page fetch stores its URL in a history stack which you can
traverse.

    $a->back();

If you want finer control over over your page fetching, you can use
these methods. C<follow_link> and C<submit_form> are just high
level wrappers around them.

    $a->follow($link);
    $a->find_link(n => $number);
    $a->form_number($number);
    $a->form_name($name);
    $a->field($name, $value);
    $a->set_fields( %field_values );
    $a->click($button);

L<WWW::Mechanize> is a proper subclass of L<LWP::UserAgent> and
you can also use any of L<LWP::UserAgent>'s methods.

    $a->add_header($name => $value);

=head1 OTHER DOCUMENTATION

=over 4

=item * L<WWW::Mechanize::Examples>

A random array of examples submitted by users.

=item * L<http://www.perl.com/pub/a/2003/01/22/mechanize.html>

Chris Ball's article about using WWW::Mechanize for scraping TV listings.

=item * L<http://www.stonehenge.com/merlyn/LinuxMag/col47.html>

Randal Schwartz's article on scraping Yahoo News for images.  It's already
out of date: He manually walks the list of links hunting for matches,
which wouldn't have been necessary if the C<find_link()> method existed
at press time.

=back

=cut

use strict;
use warnings;

use HTTP::Request;
use LWP::UserAgent;
use HTML::Form;
use HTML::TokeParser;
use URI::URL;

our @ISA = qw( LWP::UserAgent );

our %headers;

=head1 Constructor

=head2 C<< new() >>

Creates and returns a new WWW::Mechanize object, hereafter referred to as
the 'agent'.

    my $a = WWW::Mechanize->new()

The constructor for WWW::Mechanize overrides two of the parms to the
LWP::UserAgent constructor:

    agent => "WWW-Mechanize/#.##"
    cookie_jar => {}    # an empty, memory-only HTTP::Cookies object

You can override these overrides by passing parms to the constructor,
as in:

    my $a = WWW::Mechanize->new( agent=>"wonderbot 1.01" );

If you want none of the overhead of a cookie jar, or don't want your
bot accepting cookies, you have to explicitly disallow it, like so:

    my $a = WWW::Mechanize->new( cookie_jar => undef );

=cut

sub new {
    my $class = shift;

    my %default_parms = (
        agent       => "WWW-Mechanize/$VERSION",
        cookie_jar  => {},
    );

    my $self = $class->SUPER::new( %default_parms, @_ );

    $self->{page_stack} = [];
    $self->{quiet} = 0;
    $self->env_proxy();
    push( @{$self->requests_redirectable}, 'POST' );

    return bless $self, $class;
}

=head1 Page-fetching methods

=head2 C<< $a->get($url) >>

Given a URL/URI, fetches it.  Returns an C<HTTP::Response> object.

The results are stored internally in the agent object, but you don't
know that.  Just use the accessors listed below.  Poking at the internals
is deprecated and subject to change in the future.

=cut

sub get {
    my ($self, $uri) = @_;

    $uri = $self->{base}
	    ? URI->new_abs( $uri, $self->{base} )
	    : URI->new( $uri );

    my $request = HTTP::Request->new( GET => $uri );

    return $self->request( $request );
}

=head2 C<< $a->reload() >>

Acts like the reload button in a browser: Reperforms the current request.

Returns undef if there's no current request, or the C<HTTP::Response>
object from the reload.

=cut

sub reload {
    my $self = shift;

    return unless $self->{req};

    return $self->request( $self->{req} );
}

=head2 C<< $a->back() >>

The equivalent of hitting the "back" button in a browser.  Returns to
the previous page.  Won't go back past the first page. (Really, what
would it do if it could?)

=cut

sub back {
    my $self = shift;
    $self->_pop_page_stack;
}

=head1 Link-following methods

=head2 C<< $a->follow_link(...) >>

Follows a specified link on the page.  You specify the match to be
found using the same parms that C<find_link()> uses.

Here some examples:

=over 4

=item * 3rd link called "download"

    $a->follow_link( text => "download", n => 3 );

=item * first link where the URL has "download" in it, regardless of case:

    $a->follow_link( url_regex => qr/download/i );

or

    $a->follow_link( url_regex => "(?i:download)" );

=item * 3rd link on the page

    $a->follow_link( n => 3 );

=back

Returns the result of the GET method (an HTTP::Response object) if
a link was found. If the page has no links, or the specified link
couldn't be found, returns undef.

This method is meant to replace C<< $a->follow() >> which should
not be used in future development.

=cut

sub follow_link {
    my $self = shift;

    my $response;
    my $link_ref = $self->find_link(@_);
    if ( $link_ref ) {
	my $link = $link_ref->[0];     # we just want the URL, not the text
	$self->_push_page_stack();
	$response = $self->get( $link );
    }

    return $response;
}

=head2 C<< $a->follow($string|$num) >>

(Note that C<follow()> is deprecated in favor of Cfollow_link()>,
which provides more flexibility.)

Follow a link.  If you provide a string, the first link whose text
matches that string will be followed.  If you provide a number, it
will be the I<$num>th link on the page.  Note that the links are
0-based.

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
            return;
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
            return;
        }
    }

    $thislink = $thislink->[0];     # we just want the URL, not the text

    $self->_push_page_stack();
    $self->get( $thislink );

    return 1;
}

=head1 Form field filling methods

=head2 C<< $a->form($number|$name) >>

Selects a form by number or name, depending on if it gets passed an
all-numeric string or not.  If you have a form with a name that is all
digits, you'll need to call C<< $a->form_name >> explicitly.

This method is deprecated. Use C<form_name> or C<form_number> instead.

=cut

sub form {
    my $self = shift;
    my $arg = shift;

    return $arg =~ /^\d+$/ ? $self->form_number($arg) : $self->form_name($arg);
}

=head2 C<< $a->form_number($number) >>

Selects the I<number>th form on the page as the target for subsequent
calls to field() and click().  Emits a warning and returns false if there
is no such form.  Forms are indexed from 1, so the first form is number 1,
not zero.

=cut

sub form_number {
    my ($self, $form) = @_;
    if ($self->{forms}->[$form-1]) {
        $self->{form} = $self->{forms}->[$form-1];
        return 1;
    } else {
	unless ( $self->{quiet} ) {
	    require Carp;
	    Carp::carp "There is no form named $form";
	}
        return 0;
    }
}

=head2 C<< $a->form_name($name) >>

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
	unless ( $self->{quiet} ) {
	    require Carp;
	    Carp::carp "There is no form named $form";
	}
        return 0;
    }
}

=head2 C<< $a->field($name, $value, $number) >>

Given the name of a field, set its value to the value specified.  This
applies to the current form (as set by the C<form()> method or defaulting
to the first form on the page).

The optional C<$number> parameter is used to distinguish between two fields
with the same name.  The fields are numbered from 1.

=cut

sub field {
    my ($self, $name, $value, $number) = @_;
    $number ||= 1;

    my $form = $self->{form};
    if ($number > 1) {
        $form->find_input($name, undef, $number)->value($value);
    } else {
        $form->value($name => $value);
    }
}

=head2 C<< $a->set_fields( $name => $value ... ) >>

This method sets multiple fields of a form. It takes a list of field
name and value pairs. If there is more than one field with the same
name, the first one found is set. If you want to select which of the
duplicate field to set, use a value which is an anonymous array which
has the field value and its number as the 2 elements.

        # set the second foo field
        $a->set_fields( $name => [ 'foo', 2 ] ) ;

The fields are numbered from 1.

This applies to the current form (as set by the C<form()> method or
defaulting to the first form on the page).

=cut

sub set_fields {
    my ($self, %fields ) = @_;

    my $form = $self->{form};

    while( my ( $field, $value ) = each %fields ) {
        if ( ref $value eq 'ARRAY' ) {
            $form->find_input( $field, undef,
                         $value->[1])->value($value->[0] );
        } else {
            $form->value($field => $value);
        }
    }
}

=head2 C<< tick($name, $value [, $set] ) >>

'Ticks' the first checkbox that has both the name and value assoicated
with it on the current form.  Dies if there is no named check box for
that value.  Passing in a false value as the third optional argument
will cause the checkbox to be unticked.

=cut

sub tick {
    my $this = shift;
    my $name = shift;
    my $value = shift;
    my $set = @_ ? shift : 1;  # default to 1 if not passed

    # loop though all the inputs
    my $input;
    my $index = 0;
    while($input = $this->current_form->find_input($name,"checkbox",$index)) {
	# Can't guarantee that the first element will be undef and the second
	# element will be the right name
	foreach my $val ($input->possible_values()) {
	    next unless defined $val;
	    if ($val eq $value) {
		$input->value($set ? $value : undef);
		return;
	    }
	}

	# move onto the next input
	$index++;
    } # while

    # got this far?  Didn't find anything
    die "No checkbox '$name' for value '$value' in form";
} # tick()

=head2 C<< untick($name, $value) >>

Causes the checkbox to be unticked.  Shorthand for
C<tick($name,$value,undef)>

=cut

sub untick {
    shift->tick(shift,shift,undef);
}

=head1 Form submission methods

=head2 C<< $a->click( $button [, $x, $y] ) >>

Has the effect of clicking a button on a form.  The first argument
is the name of the button to be clicked.  The second and third
arguments (optional) allow you to specify the (x,y) coordinates
of the click.

If there is only one button on the form, C<< $a->click() >> with
no arguments simply clicks that one button.

Returns an L<HTTP::Response> object.

=cut

sub click {
    my ($self, $button, $x, $y) = @_;
    for ($x, $y) { $_ = 1 unless defined; }
    $self->_push_page_stack();
    my $request = $self->{form}->click($button, $x, $y);
    return $self->request( $request );
}

=head2 C<< $a->submit() >>

Submits the page, without specifying a button to click.  Actually,
no button is clicked at all.

This used to be a synonym for C<< $a->click("submit") >>, but is no
longer so.

=cut

sub submit {
    my $self = shift;

    $self->_push_page_stack();
    my $request = $self->{form}->make_request;
    return $self->request( $request );
}

=head2 C<< $a->submit_form( ... ) >>

This method lets you select a form from the previously fetched page,
fill in its fields, and submit it. It combines the form_number/form_name,
set_fields and click methods into one higher level call. Its arguments
are a list of key/value pairs, all of which are optional.

=over 4

=item * form_number => n

Selects the I<n>th form (calls C<form_number()>)

=item * form_name => name

Selects the form named I<name> (calls C<form_name()>)

=item * fields => fields

Sets the field values from the I<fields> hashref (calls C<set_fields()>)

=item * button => button

Clicks on button I<button> (calls C<click()>)

=item * x => x, y => y

Sets the x or y values for C<click()>

=back

If no form is selected, the first form found is used.

If I<button> is not passed, then the C<submit()> method is used instead.

Returns an HTTP::Response object.

=cut

sub submit_form {
    my( $self, %args ) = @_ ;

    if ( my $form_number = $args{'form_number'} ) {
	$self->form_number( $form_number ) ;
    }
    elsif ( my $form_name = $args{'form_name'} ) {
        $self->form_name( $form_name ) ;
    }
    else {
        $self->form_number( 1 ) ;
    }

    if ( my $fields = $args{'fields'} ) {
        if ( ref $fields eq 'HASH' ) {
	    $self->set_fields( %{$fields} ) ;
        } # TODO: What if it's not a hash?  We just ignore it silently?
    }

    my $response;
    if ( $args{button} ) {
	$response = $self->click( $args{button}, $args{x} || 0, $args{y} || 0 );
    } else {
	$response = $self->submit();
    }

    return $response;
}

=head1 Status methods

=head2 C<< $a->success() >>

Returns a boolean telling whether the last request was successful.
If there hasn't been an operation yet, returns false.

This is a convenience function that wraps C<< $a->res->is_success >>.

=cut

sub success {
    my $self = shift;

    return $self->res && $self->res->is_success;
}


=head2 C<< $a->uri() >>

Returns the current URI.

=head2 C<< $a->response() >> or C<< $a->res() >>

Return the current response as an C<HTTP::Response> object.

Synonym for C<< $a->response() >>

=head2 C<< $a->status() >>

Returns the HTTP status code of the response.

=head2 C<< $a->ct() >>

Returns the content type of the response.

=head2 C<< $a->base() >>

Returns the base URI for the current response

=head2 C<< $a->content() >>

Returns the content for the response

=head2 C<< $a->forms() >>

When called in a list context, returns a list of the forms found in
the last fetched page. In a scalar context, returns a reference to
an array with those forms. The forms returned are all C<HTML::Form>
objects.

=head2 C<< $a->current_form() >>

Returns the current form as an C<HTML::Form> object.  I'd call this
C<form()> except that C<form()> already exists and sets the current_form.

=head2 C<< $a->links() >>

When called in a list context, returns a list of the links found in
the last fetched page. In a scalar context it returns a reference to
an array with those links. The links returned are all references to
two element arrays which contain the URL and the text for each link.

=head2 C<< $a->is_html() >>

Returns true/false on whether our content is HTML, according to the
HTTP headers.

=cut

sub uri {           my $self = shift; return $self->{uri}; }
sub res {           my $self = shift; return $self->{res}; }
sub response {      my $self = shift; return $self->{res}; }
sub status {        my $self = shift; return $self->{status}; }
sub ct {            my $self = shift; return $self->{ct}; }
sub base {          my $self = shift; return $self->{base}; }
sub content {       my $self = shift; return $self->{content}; }
sub current_form {  my $self = shift; return $self->{form}; }
sub is_html {       my $self = shift; return defined $self->{ct} && ($self->{ct} eq "text/html"); }

sub links {
    my $self = shift ;
    return @{$self->{links}} if wantarray;
    return $self->{links};
}

sub forms {
    my $self = shift ;
    return @{$self->{forms}} if wantarray;
    return $self->{forms};
}


=head2 C<< $a->title() >>

Returns the contents of the C<< <TITLE> >> tag, as parsed by
HTML::HeadParser.  Returns undef if the content is not HTML.

=cut

sub title {
    my $self = shift;
    return unless $self->is_html;

    require HTML::HeadParser;
    my $p = HTML::HeadParser->new;
    $p->parse($self->content);
    return $p->header('Title');
}

=head1 Content-handling methods

=head2 C<< $a->extract_links() >>

Extracts HREF links from the content of a webpage.

The return value is a reference to an array containing
an array reference for every C<< <A> >>, C<< <FRAME> >>
or C<< <IFRAME> >> tag in C<< $self->{content} >>.  

The array elements for the C<< <A> >> tag are: 

=over 4

=item [0]: contents of the C<href> attribute

=item [1]: text enclosed by the C<< <A> >> tag

=item [2]: the contents of the C<name> attribute

=back

The array elements for the C<< <FRAME> >> and 
C<< <IFRAME> >> tags are:

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

    while (my $token = $p->get_tag("a", "frame", "iframe")) {
        my $tag_is_a = ($token->[0] eq 'a');
        my $url = $tag_is_a ? $token->[1]{href} : $token->[1]{src};
        next unless defined $url;   # probably just a name link

        my $text = $tag_is_a ? $p->get_trimmed_text("/a") : $token->[1]{name};
        my $name = $token->[1]{name};
        push(@links, [$url, $text, $name]);
    }
    return \@links;
}

=head2 C<< $a->find_link() >>

This method finds a link in the currently fetched page. It returns
a reference to a two element array which has the link URL and link
text, respectively. If it fails to find a link it returns undef.
You can take the URL part and pass it to the C<get> method. The
C<follow_link> method is recommended as it calls this method and
also does the C<get> for you.

Note that C<< <FRAME SRC="..." >> tags are parsed out of the the
HTML and treated as links so this method works with them.

You can select which link to find by passing in one of these
key/value pairs:

=over 4

=item * text => string

Matches the text of the link against I<string>, which must be an
exact match.

To select a link with text that is exactly "download", use

    $a->find_link( text => "download" );

=item * text_regex => regex

Matches the text of the link against I<regex>.

To select a link with text that has "download" anywhere in it,
regardless of case, use

    $a->find_link( text_regex => qr/download/i );

=item * url => string

Matches the URL of the link against I<string>, which must be an
exact match.  This is similar to the C<text> parm.

=item * url_regex => regex

Matches the URL of the link against I<regex>.  This is similar to
the C<text_regex> parm.

=item * n => I<number or "all">

Matches against the I<n>th link.  If I<n> is the string "all", then
all links matching the criteria are returned.

The C<n> parms can be combined with the C<text*> or C<url*> parms
as a numeric modifier.  For example, 
C<< text => "download", n => 3 >> finds the 3rd link which has the
exact text "download", and
C<< text => "download", n => "all" >> finds all download links.

=back

If C<n> is not specified, it defaults to 1.  Therefore, if you don't
specify any parms, this method defaults to finding the first link on the
page.

=cut

sub find_link {
    my $self = shift;
    my %parms = ( n=>1, @_ );

    my @links = @{$self->{links}};

    return unless @links ;

    my @matches;
    my $match;
    my $arg;
    my $wantall = ( $parms{n} eq "all" );

    if ( !$self->quiet ) {
	for ( keys %parms ) {
	    warn qq{Unknown link-finding parameter "$_"\n}
		unless /^(n|(text|url)(_regex)?)$/;
	}
    }

    if ( defined ($arg = $parms{url}) ) {
	$match = sub { $_[0]->[0] eq $arg };

    } elsif ( defined ($arg = $parms{url_regex}) ) {
	$match = sub { $_[0]->[0] =~ $arg }

    } elsif ( defined ($arg = $parms{text}) ) {
	$match = sub { $_[0]->[1] eq $arg };

    } elsif ( defined ($arg = $parms{text_regex} )) {
	$match = sub { $_[0]->[1] =~ $arg }

    } else {
	$match = sub { 1 };
    }

    my $nmatches = 0;
    for my $link ( @links ) {
	if ( $match->($link) ) {
	    push( @matches, $link );
	    return $link if !$wantall && (scalar @matches >= $parms{n});
	}
    } # for @links

    return @matches if $wantall;
    return;
} # find_link


=head1 Miscellaneous methods

=head2 C<< $a->add_header(name => $value) >>

Sets a header for the WWW::Mechanize agent to use every time it gets
a webpage.  This is B<NOT> stored in the agent object (because if it
were, it would disappear if you went back() past where you'd set it)
but in the hash variable C<%WWW::Mechanize::headers>, which is a hash of
all headers to be set.  You can manipulate this directly if you want to;
the add_header() method is just provided as a convenience function for
the most common case of adding a header.

=cut

sub add_header {
    my ($self, $name, $value) = @_;
    $WWW::Mechanize::headers{$name} = $value;
}

=head2 C<< $a->quiet(true/false) >>

Allows you to suppress warnings to the screen.

    $a->quiet(0); # turns on warnings (the default)
    $a->quiet(1); # turns off warnings
    $a->quiet();  # returns the current quietness status

=cut

sub quiet {
    my $self = shift;

    $self->{quiet} = $_[0] if @_;

    return $self->{quiet};
}

=head1 INTERNAL METHODS

These methods are only used internally.  You probably don't need to 
know about them.

=head2 C<< $a->_push_page_stack() >> and C<< $a->_pop_page_stack() >>

The agent keeps a stack of visited pages, which it can pop when it needs
to go BACK and so on.  

The current page needs to be pushed onto the stack before we get a new
page, and the stack needs to be popped when BACK occurs.

Neither of these take any arguments, they just operate on the $a
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
            delete $self->{ $key }              unless $key eq 'page_stack';
        }

        # make self just like the popped object
        foreach my $key ( keys %$popped ) {
            $self->{ $key } = $popped->{ $key } unless $key eq 'page_stack';
        }
    }

    return 1;
}


=head2 C<< redirect_ok() >>

Keep track of the last uri redirected to, and tell our parent that it's
OK to do the redirect.

=cut

sub redirect_ok {
    $_[0]->{redirected_uri} = $_[1]->uri;

    return 1;
};


=head2 C<< $a->request( $request [, $arg [, $size]]) >>

Overloaded version of C<request()> in L<LWP::UserAgent>.  Performs
the actual request.  Normally, if you're using WWW::Mechanize, it'd
because you don't want to deal with this level of stuff anyway.

Note that C<$request> will be modified.

Returns an L<HTTP::Response> object.

=cut


sub request {
    my $self = shift;
    my $request = shift;

    $request->header( Referer => $self->{last_uri} ) if $self->{last_uri};
    while ( my($key,$value) = each %WWW::Mechanize::headers ) {
        $request->header( $key => $value );
    }
    $self->{req} = $request;
    $self->{redirected_uri} = $request->uri;
    $self->{res} = $self->SUPER::request( $request, @_ );

    # These internal hash elements should be dropped in favor of
    # the accessors soon. -- 1/19/03
    $self->{status}  = $self->{res}->code;
    $self->{base}    = $self->{res}->base;
    $self->{ct}      = $self->{res}->content_type || "";
    $self->{content} = $self->{res}->content;
    if ( $self->{res}->is_success ) {
	$self->{uri} = $self->{redirected_uri};
	$self->{last_uri} = $self->{uri};
    }

    if ( $self->is_html ) {
        $self->{forms} = [ HTML::Form->parse($self->{content}, $self->{res}->base) ];
        $self->{form}  = @{$self->{forms}} ? $self->{forms}->[0] : undef;
        $self->{links} = $self->extract_links();
    }

    return $self->{res};
}

=head1 FAQ

=head2 I tried to [such-and-such] and I got this weird error.

Are you checking your errors?

Are you sure?

Are you checking that your action succeeded after every action?

Are you sure?

For example, if you try this:

    $mech->get( "http://my.site.com" );
    $mech->follow_link( "foo" );

and the C<get> call fails for some reason, then the Mech internals
will be unusable for the C<follow_link> and you'll get a weird
error.  You B<must>, after every action that GETs or POSTs a page,
check that Mech succeeded, or all bets are off.

    $mech->get( "http://my.site.com" );
    die "Can't even get the home page: ", $mech->response->status_line
	unless $mech->success;

    $mech->follow_link( "foo" );
    die "Foo link failed: ", $mech->response->status_line
	unless $mech->success;

I guarantee you this will be the very first thing that I ask if
you mail me about a problem with Mech.

=head2 Can I do [such-and-such] with WWW::Mechanize?

If it's possible with LWP::UserAgent, then yes.  WWW::Mechanize is
a subclass of L<LWP::UserAgent>, so all the wondrous magic of that
class is inherited.

=head2 How do I use WWW::Mechanize through a proxy server?

See the docs in LWP::UserAgent on how to use the proxy.  Short
version:

    $a->proxy(['http', 'ftp'], 'http://proxy.example.com:8000/');

or get the specs from the environment:

    $a->env_proxy();

    # Environment set like so:
    gopher_proxy=http://proxy.my.place/
    wais_proxy=http://proxy.my.place/
    no_proxy="localhost,my.domain"
    export gopher_proxy wais_proxy no_proxy


=head1 TODO

Fix failures on t/back.t

Make t/tick.t run off the local server

Make it easier to save content.

Make a method that finds all the IMG SRC

Allow saving content to a file

=head1 SEE ALSO

See also L<WWW::Mechanize::Examples> for sample code.
L<WWW::Mechanize::FormFiller> and L<WWW::Mechanize::Shell> are add-ons
that turn Mechanize into more of a scripting tool.

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
