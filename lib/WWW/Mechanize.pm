package WWW::Mechanize;

=head1 NAME

WWW::Mechanize - Handy web browsing in a Perl object

=head1 VERSION

Version 0.73_03

    $Header: /cvsroot/www-mechanize/www-mechanize/lib/WWW/Mechanize.pm,v 1.118 2004/03/23 04:50:08 petdance Exp $

=cut

our $VERSION = "0.73_03";

=head1 SYNOPSIS

C<WWW::Mechanize>, or Mech for short, helps you automate interaction with
a website. It supports performing a sequence of page fetches including
following links and submitting forms. Each fetched page is parsed and
its links and forms are extracted. A link or a form can be selected, form
fields can be filled and the next page can be fetched. Mech also stores
a history of the URLs you've visited, which can be queried and revisited.

    use WWW::Mechanize;
    my $mech = WWW::Mechanize->new();

    $mech->get( $url );

    $mech->follow_link( n => 3 );
    $mech->follow_link( text_regex => qr/download this/i );
    $mech->follow_link( url => 'http://host.com/index.html' );

    $mech->submit_form(
        form_number => 3,
        fields      => {
                        username    => 'yourname',
                        password    => 'dummy',
                        }
    );

    $mech->submit_form(
        form_name => 'search',
        fields    => { query  => 'pot of gold', },
        button    => 'Search Now'
    );


Mech is well suited for use in testing web applications.  If you use
one of the Test::*, like L<Test::HTML::Lint> modules, you can check the
fetched content and use that as input to a test call.

    use Test::More;
    like( $mech->content(), qr/$expected/, "Got expected content" );

Each page fetch stores its URL in a history stack which you can
traverse.

    $mech->back();

If you want finer control over over your page fetching, you can use
these methods. C<follow_link> and C<submit_form> are just high
level wrappers around them.

    $mech->follow( $link );
    $mech->find_link( n => $number );
    $mech->form_number( $number );
    $mech->form_name( $name );
    $mech->field( $name, $value );
    $mech->set_fields( %field_values );
    $mech->set_visible( @criteria );
    $mech->click( $button );

L<WWW::Mechanize> is a proper subclass of L<LWP::UserAgent> and
you can also use any of L<LWP::UserAgent>'s methods.

    $mech->add_header($name => $value);

=head1 IMPORTANT LINKS

=over 4

=item * L<http://search.cpan.org/dist/WWW-Mechanize/>

The CPAN documentation page for Mechanize.

=item * L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize>

The RT queue for bugs & enhancements in Mechanize.  Click the "Report bug"
link if your bug isn't already reported.

=back

=cut

use strict;
use warnings;

use HTTP::Request 1.30;
use LWP::UserAgent 2.003;
use HTML::Form 1.00;
use HTML::TokeParser;
use URI::URL;

our @ISA = qw( LWP::UserAgent );

our %headers;

=head1 Constructor and startup

=head2 new()

Creates and returns a new WWW::Mechanize object, hereafter referred to as
the 'agent'.

    my $mech = WWW::Mechanize->new()

The constructor for WWW::Mechanize overrides two of the parms to the
LWP::UserAgent constructor:

    agent => "WWW-Mechanize/#.##"
    cookie_jar => {}    # an empty, memory-only HTTP::Cookies object

You can override these overrides by passing parms to the constructor,
as in:

    my $mech = WWW::Mechanize->new( agent=>"wonderbot 1.01" );

If you want none of the overhead of a cookie jar, or don't want your
bot accepting cookies, you have to explicitly disallow it, like so:

    my $mech = WWW::Mechanize->new( cookie_jar => undef );

Here are the parms that WWW::Mechanize recognizes.  These do not include
parms that L<LWP::UserAgent> recognizes.

=over 4

=item * C<< autocheck => [0|1] >>

Checks each request made to see if it was successful.  This saves you
the trouble of manually checking yourself.  Any errors found are errors,
not warnings.  Default is off.

=item * C<< onwarn => \&func() >>

Reference to a C<warn>-compatible function, such as C<< L<Carp>::carp >>,
that is called when a warning needs to be shown.

If this is set to C<undef>, no warnings will ever be shown.  However,
it's probably better to use the C<quiet> method to control that behavior.

If this value is not passed, Mech uses C<Carp::carp> if L<Carp> is
installed, or C<CORE::warn> if not.

=item * C<< onerror => \&func() >>

Reference to a C<die>-compatible function, such as C<< L<Carp>::croak >>,
that is called when there's a fatal error.

If this is set to C<undef>, no errors will ever be shown.

If this value is not passed, Mech uses C<Carp::croak> if L<Carp> is
installed, or C<CORE::die> if not.

=item * C<< quiet => [0|1] >>

Don't complain on warnings.  Setting C<< quiet => 1 >> is the same as
calling C<< $agent->quiet(1) >>.  Default is off.

=back

=cut

sub new {
    my $class = shift;

    my %parent_parms = (
        agent       => "WWW-Mechanize/$VERSION",
        cookie_jar  => {},
    );

    my %mech_parms = (
        autocheck   => 0,
        onwarn      => \&WWW::Mechanize::_warn,
        onerror     => \&WWW::Mechanize::_die,
        quiet       => 0,
    );

    my %passed_parms = @_;

    # Keep the mech-specific parms before creating the object.
    while ( my($key,$value) = each %passed_parms ) {
        if ( exists $mech_parms{$key} ) {
            $mech_parms{$key} = $value;
        } else {
            $parent_parms{$key} = $value;
        }
    }

    my $self = $class->SUPER::new( %parent_parms );
    bless $self, $class;

    # Use the mech parms now that we have a mech object.
    for my $parm ( keys %mech_parms ) {
        $self->{$parm} = $mech_parms{$parm};
    }
    $self->{page_stack} = [];
    $self->env_proxy();
    push( @{$self->requests_redirectable}, 'POST' );

    $self->_reset_page;

    return $self;
}

=head2 $mech->agent_alias( $alias )

Sets the user agent string to the expanded version from a table of actual user strings.
I<$alias> can be one of the following:

=over 4

=item * Windows IE 6

=item * Windows Mozilla

=item * Mac Safari

=item * Mac Mozilla

=item * Linux Mozilla

=item * Linux Konqueror

=back

then it will be replaced with a more interesting one.  For instance,

    $mech->agent_alias( 'Windows IE 6' );

sets your User-Agent to

    Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)

The list of valid aliases can be returned from C<known_agent_aliases()>.

=cut

my %known_agents = (
    'Windows IE 6'      => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
    'Windows Mozilla'   => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
    'Mac Safari'        => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/85 (KHTML, like Gecko) Safari/85',
    'Mac Mozilla'       => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',
    'Linux Mozilla'     => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
    'Linux Konqueror'   => 'Mozilla/5.0 (compatible; Konqueror/3; Linux)',
);

sub agent_alias {
    my $self = shift;
    my $alias = shift;

    if ( defined $known_agents{$alias} ) {
        return $self->agent( $known_agents{$alias} );
    } else {
        $self->warn( qq{Unknown agent alias "$alias"} );
        return $self->agent();
    }
}

=head2 C<known_agent_aliases()>

Returns a list of all the agent aliases that Mech knows about.

=cut

sub known_agent_aliases {
    return sort keys %known_agents;
}

=head1 Page-fetching methods

=head2 $mech->get($url)

Given a URL/URI, fetches it.  Returns an L<HTTP::Response> object.
I<$url> can be a well-formed URL string, or a L<URI> object.

The results are stored internally in the agent object, but you don't
know that.  Just use the accessors listed below.  Poking at the internals
is deprecated and subject to change in the future.

C<get()> is a well-behaved overloaded version of the method in
L<LWP::UserAgent>.  This lets you do things like

    $mech->get( $url, ":content_file"=>$tempfile );

and you can rest assured that the parms will get filtered down
appropriately.

=cut

sub get {
    my $self = shift;
    my $uri = shift;

    $uri = $self->base
            ? URI->new_abs( $uri, $self->base )
            : URI->new( $uri );

    return $self->SUPER::get( $uri->as_string, @_ );
}

=head2 $mech->reload()

Acts like the reload button in a browser: Reperforms the current
request.

Returns the L<HTTP::Response> object from the reload, or C<undef>
if there's no current request.

=cut

sub reload {
    my $self = shift;

    return unless $self->{req};

    return $self->request( $self->{req} );
}

=head2 $mech->back()

The equivalent of hitting the "back" button in a browser.  Returns to
the previous page.  Won't go back past the first page. (Really, what
would it do if it could?)

=cut

sub back {
    my $self = shift;
    $self->_pop_page_stack;
}

=head1 Link-following methods

=head2 $mech->follow_link(...)

Follows a specified link on the page.  You specify the match to be
found using the same parms that C<L<find_link()>> uses.

Here some examples:

=over 4

=item * 3rd link called "download"

    $mech->follow_link( text => "download", n => 3 );

=item * first link where the URL has "download" in it, regardless of case:

    $mech->follow_link( url_regex => qr/download/i );

or

    $mech->follow_link( url_regex => qr/(?i:download)/ );

=item * 3rd link on the page

    $mech->follow_link( n => 3 );

=back

Returns the result of the GET method (an HTTP::Response object) if
a link was found. If the page has no links, or the specified link
couldn't be found, returns undef.

This method is meant to replace C<< $mech->follow() >> which should
not be used in future development.

=cut

sub follow_link {
    my $self = shift;
    my %parms = ( n=>1, @_ );

    if ( $parms{n} eq "all" ) {
        delete $parms{n};
        $self->warn( qq{follow_link(n=>"all") is not valid} );
    }

    my $response;
    my $link = $self->find_link(%parms);
    if ( $link ) {
        $response = $self->get( $link->url );
    }

    return $response;
}

=head1 Form field filling methods

=head2 $mech->form_number($number)

Selects the I<number>th form on the page as the target for subsequent
calls to C<L<field()>> and C<L<click()>>.  Also returns the form that was
selected.  Emits a warning and returns undef if there is no such
form.  Forms are indexed from 1, so the first form is number 1,
not zero.

=cut

sub form_number {
    my ($self, $form) = @_;
    if ($self->{forms}->[$form-1]) {
        $self->{form} = $self->{forms}->[$form-1];
        return $self->{form};
    } else {
        $self->warn( "There is no form numbered $form" );
        return undef;
    }
}

=head2 $mech->form_name($name)

Selects a form by name.  If there is more than one form on the page
with that name, then the first one is used, and a warning is
generated.  Also returns the form itself, or undef if it's not
found.

Note that this functionality requires libwww-perl 5.69 or higher.

=cut

sub form_name {
    my ($self, $form) = @_;

    my $temp;
    my @matches = grep {defined($temp = $_->attr('name')) and ($temp eq $form) } $self->forms;
    if ( @matches ) {
        $self->warn( "There are ", scalar @matches, " forms named $form.  The first one was used." )
            if @matches > 1;
        return $self->{form} = $matches[0];
    } else {
        $self->warn( qq{ There is no form named "$form"} );
        return undef;
    }
}

=head2 $mech->field( $name, $value, $number )

=head2 $mech->field( $name, \@values, $number )

Given the name of a field, set its value to the value specified.  This
applies to the current form (as set by the C<L<form()>> method or defaulting
to the first form on the page).

The optional I<$number> parameter is used to distinguish between two fields
with the same name.  The fields are numbered from 1.

=cut

sub field {
    my ($self, $name, $value, $number) = @_;
    $number ||= 1;

    my $form = $self->{form};
    if ($number > 1) {
        $form->find_input($name, undef, $number)->value($value);
    } else {
        if ( ref($value) eq "ARRAY" ) {
            $form->param($name, $value);
        } else {
            $form->value($name => $value);
        }
    }
}

=head2 $mech->set_fields( $name => $value ... )

This method sets multiple fields of a form. It takes a list of field
name and value pairs. If there is more than one field with the same
name, the first one found is set. If you want to select which of the
duplicate field to set, use a value which is an anonymous array which
has the field value and its number as the 2 elements.

        # set the second foo field
        $mech->set_fields( $name => [ 'foo', 2 ] ) ;

The fields are numbered from 1.

This applies to the current form (as set by the C<L<form()>> method or
defaulting to the first form on the page).

=cut

sub set_fields {
    my $self = shift;
    my %fields = @_;

    my $form = $self->current_form;

    while ( my ( $field, $value ) = each %fields ) {
        if ( ref $value eq 'ARRAY' ) {
            $form->find_input( $field, undef,
                         $value->[1])->value($value->[0] );
        } else {
            $form->value($field => $value);
        }
    } # while
} # set_fields()


=head2 $mech->set_visible( @criteria )

This method sets fields of a form without having to know their
names.  So if you have a login screen that wants a username and
password, you do not have to fetch the form and inspect the source
(or use the F<mech-dump> utility, installed with WWW::Mechanize)
to see what the field names are; you can just say

    $mech->set_visible( $username, $password ) ;

and the first and second fields will be set accordingly.  The method
is called set_I<visible> because it acts only on visible fields;
hidden form inputs are not considered.  The order of the fields is
the order in which they appear in the HTML source which is nearly
always the order anyone viewing the page would think they are in,
but some creative work with tables could change that; caveat user.

Each element in C<@criteria> is either a field value or a field
specifier.  A field value is a scalar.  A field specifier allows
you to specify the I<type> of input field you want to set and is
denoted with an arrayref containing two elements.  So you could
specify the first radio button with

    $mech->set_visible( [ radio => "KCRW" ] ) ;

Field values and specifiers can be intermixed, hence

    $mech->set_visible( "fred", "secret", [ option => "Checking" ] ) ;

would set the first two fields to "fred" and "secret", and the I<next>
C<OPTION> menu field to "Checking".

The possible field specifier types are: "text", "password", "hidden",
"textarea", "file", "image", "submit", "radio", "checkbox" and "option".

=cut

sub set_visible {
    my $self = shift;

    my $form = $self->current_form;
    my @inputs = $form->inputs;

    while (my $value = shift) {
        if ( ref $value eq 'ARRAY' ) {
           my ( $type, $value ) = @$value;
           while ( my $input = shift @inputs ) {
               next if $input->type eq 'hidden';
               if ( $input->type eq $type ) {
                   $input->value( $value );
                   last;
               }
           } # while
        } else {
           while ( my $input = shift @inputs ) {
               next if $input->type eq 'hidden';
               $input->value( $value );
               last;
           } # while
       }
    } # while

} # set_visible()

=head2 $mech->tick( $name, $value [, $set] )

'Ticks' the first checkbox that has both the name and value assoicated
with it on the current form.  Dies if there is no named check box for
that value.  Passing in a false value as the third optional argument
will cause the checkbox to be unticked.

=cut

sub tick {
    my $self = shift;
    my $name = shift;
    my $value = shift;
    my $set = @_ ? shift : 1;  # default to 1 if not passed

    # loop though all the inputs
    my $index = 0;
    while ( my $input = $self->current_form->find_input( $name, "checkbox", $index ) ) {
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

    # got self far?  Didn't find anything
    $self->warn( qq{No checkbox "$name" for value "$value" in form} );
} # tick()

=head2 $mech->untick($name, $value)

Causes the checkbox to be unticked.  Shorthand for
C<tick($name,$value,undef)>

=cut

sub untick {
    shift->tick(shift,shift,undef);
}

=head1 Form submission methods

=head2 $mech->click( $button [, $x, $y] )

Has the effect of clicking a button on a form.  The first argument
is the name of the button to be clicked.  The second and third
arguments (optional) allow you to specify the (x,y) coordinates
of the click.

If there is only one button on the form, C<< $mech->click() >> with
no arguments simply clicks that one button.

Returns an L<HTTP::Response> object.

=cut

sub click {
    my ($self, $button, $x, $y) = @_;
    for ($x, $y) { $_ = 1 unless defined; }
    my $request = $self->{form}->click($button, $x, $y);
    return $self->request( $request );
}

=head2 $mech->click_button( ... ) 

Has the effect of clicking a button on a form by specifying its name,
value, or index.  Its arguments are a list of key/value pairs.  Only
one of name, number, or value must be specified.

TODO: This function has no tests.

=over 4

=item * name => name

Clicks the button named I<name>.

=item * number => n

Clicks the I<n>th button in the form.

=item * value => value

Clicks the button with the value I<value>.

=item * x => x
=item * y => y

These arguments (optional) allow you to specify the (x,y) coordinates
of the click.

=back

=cut

sub click_button {
    my $self = shift;
    my %args = @_;

    for ( keys %args ) {
        if ( !/^(number|name|value|x|y)$/ ) {
            $self->warn( qq{Unknown click_button_form parameter "$_"} );
        }
    }

    for ($args{x}, $args{y}) { $_ = 1 unless defined; }
    my $form = $self->{form};
    my $request;
    if ( $args{name} ) {
        $request = $form->click( $args{name}, $args{x}, $args{y} );
    } elsif ( $args{number} ) {
        my $input = $form->find_input( undef, 'submit', $args{number} );
        $request = $input->click( $form, $args{x}, $args{y} );
    } elsif ( $args{value} ) {
        my $i = 1;
        while ( my $input = $form->find_input(undef, 'submit', $i) ) {
            if ( $args{value} && ($args{value} eq $input->value) ) {
                $request = $input->click( $form, $args{x}, $args{y} );
                last;
            }
            $i++;
        } # while
    } # $args{value}

    return $self->request( $request );
}

=head2 $mech->select($name, $value) 

=head2 $mech->select($name, \@values) 

Given the name of a C<select> field, set its value to the value
specified.  If the field is not E<lt>select multipleE<gt> and the
C<$value> is an array, only the last value will be set.  This applies
to the current form (as set by the C<L<form()>> method or defaulting
to the first form on the page).

=cut

sub select {
    my ($self, $name, $value) = @_;

    my $form = $self->{form};

    my $input = $form->find_input($name);
    if (!$input) {
        $self->warn( qq{ Input "$name" not found } );
        return;
    } elsif ($input->type ne 'option') {
        $self->warn( qq{ Input "$name" is not type "select" } );
        return;
    }

    if (ref($value) eq "ARRAY") {
        $form->param($name, $value);
    } else {
        $form->value($name => $value);
    }
}

=head2 $mech->submit()

Submits the page, without specifying a button to click.  Actually,
no button is clicked at all.

This used to be a synonym for C<< $mech->click("submit") >>, but is no
longer so.

=cut

sub submit {
    my $self = shift;

    my $request = $self->{form}->make_request;
    return $self->request( $request );
}

=head2 $mech->submit_form( ... )

This method lets you select a form from the previously fetched page,
fill in its fields, and submit it. It combines the form_number/form_name,
set_fields and click methods into one higher level call. Its arguments
are a list of key/value pairs, all of which are optional.

=over 4

=item * form_number => n

Selects the I<n>th form (calls C<L<form_number()>>).  If this parm is not
specified, the currently-selected form is used.

=item * form_name => name

Selects the form named I<name> (calls C<L<form_name()>>)

=item * fields => fields

Sets the field values from the I<fields> hashref (calls C<L<set_fields()>>)

=item * button => button

Clicks on button I<button> (calls C<L<click()>>)

=item * x => x, y => y

Sets the x or y values for C<L<click()>>

=back

If no form is selected, the first form found is used.

If I<button> is not passed, then the C<L<submit()>> method is used instead.

Returns an L<HTTP::Response> object.

=cut

sub submit_form {
    my( $self, %args ) = @_ ;

    for ( keys %args ) {
        if ( !/^(form_(number|name)|fields|button|x|y)$/ ) {
            $self->warn( qq{Unknown submit_form parameter "$_"} );
        }
    }

    if ( my $form_number = $args{'form_number'} ) {
        $self->form_number( $form_number ) ;
    }
    elsif ( my $form_name = $args{'form_name'} ) {
        $self->form_name( $form_name ) ;
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

=head2 $mech->success()

Returns a boolean telling whether the last request was successful.
If there hasn't been an operation yet, returns false.

This is a convenience function that wraps C<< $mech->res->is_success >>.

=cut

sub success {
    my $self = shift;

    return $self->res && $self->res->is_success;
}


=head2 $mech->uri()

Returns the current URI.

=head2 $mech->response() / $mech->res()

Return the current response as an L<HTTP::Response> object.

Synonym for C<< $mech->response() >>

=head2 $mech->status()

Returns the HTTP status code of the response.

=head2 $mech->ct()

Returns the content type of the response.

=head2 $mech->base()

Returns the base URI for the current response

=head2 $mech->content()

Returns the content for the response

=head2 $mech->forms()

When called in a list context, returns a list of the forms found in
the last fetched page. In a scalar context, returns a reference to
an array with those forms. The forms returned are all L<HTML::Form>
objects.

=head2 $mech->current_form()

Returns the current form as an L<HTML::Form> object.  I'd call this
C<form()> except that C<L<form()>> already exists and sets the current_form.

=head2 $mech->links()

When called in a list context, returns a list of the links found in the
last fetched page.  In a scalar context it returns a reference to an array
with those links.  Each link is a L<WWW::Mechanize::Link> object.

=head2 $mech->is_html()

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


=head2 $mech->title()

Returns the contents of the C<< <TITLE> >> tag, as parsed by
L<HTML::HeadParser>.  Returns undef if the content is not HTML.

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

=head2 $mech->find_link()

This method finds a link in the currently fetched page. It returns a
L<WWW::Mechanize::Link> object which describes the link.  (You'll probably
be most interested in the C<url()> property.)  If it fails to find a
link it returns undef.

You can take the URL part and pass it to the C<L<get()>> method.
If that's your plan, you might as well use the C<L<follow_link()>>
method directly, since it does the C<L<get()>> for you automatically.

Note that C<< <FRAME SRC="..."> >> tags are parsed out of the the HTML
and treated as links so this method works with them.

You can select which link to find by passing in one or more of these
key/value pairs:

=over 4

=item * C<< text => string >> and C<< text_regex => regex >>

C<text> matches the text of the link against I<string>, which must be an
exact match.  To select a link with text that is exactly "download", use

    $mech->find_link( text => "download" );

C<text_regex> matches the text of the link against I<regex>.  To select a
link with text that has "download" anywhere in it, regardless of case, use

    $mech->find_link( text_regex => qr/download/i );

Note that the text extracted from the page's links are trimmed.  For
example, C<< <a> foo </a> >> is stored as 'foo', and searching for
leading or trailing spaces will fail.

=item * C<< url => string >> and C<< url_regex => regex >>

Matches the URL of the link against I<string> or I<regex>, as appropriate.

=item * C<< name => string >> and C<< name_regex => regex >>

Matches the name of the link against I<string> or I<regex>, as appropriate.

=item * C<< tag => string >> and C<< tag_regex => regex >>

Matches the tag that the link came from against I<string> or I<regex>,
as appropriate.  The C<tag_regex> is probably most useful to check for
more than one tag, as in:

    $mech->find_link( tag_regex => qr/^(a|img)$/;

=item * C<< n => number >>

Matches against the I<n>th link.

The C<n> parms can be combined with the other parms above as a numeric
modifier.  For example,
C<< text => "download", n => 3 >> finds the 3rd link which has the
exact text "download".

=back

If C<n> is not specified, it defaults to 1.  Therefore, if you don't
specify any parms, this method defaults to finding the first link on the
page.

Note that you can specify multiple text or URL parameters, which
will be ANDed together.  For example, to find the first link with
text of "News" and with "cnn.com" in the URL, use:

    $mech->find_link( text => "News", url_regex => qr/cnn\.com/ );

=head2 $mech->find_link() : link format

The return value is a reference to an array containing
a L<WWW::Mechanize::Link> object for every link in
C<< $self->content >>.

The links come from the following:

=over 4

=item C<< <A HREF=...> >>

=item C<< <AREA HREF=...> >>

=item C<< <FRAME SRC=...> >>

=item C<< <IFRAME SRC=...> >>

=back

=cut

sub find_link {
    my $self = shift;
    my %parms = ( n=>1, @_ );

    my $wantall = ( $parms{n} eq "all" );

    for my $key ( keys %parms ) {
        my $val = $parms{$key};
        if ( $key !~ /^(n|(text|url|name|tag)(_regex)?)$/ ) {
            $self->warn( qq{Unknown link-finding parameter "$key"} );
            delete $parms{$key};
            next;
        }

        if ( ($key =~ /_regex$/) && (ref($val) ne "Regexp" ) ) {
            $self->warn( qq{$val passed as $key is not a regex} );
            delete $parms{$key};
            next;
        }

        if ($key !~ /_regex$/) {
            if (ref($val) eq "Regexp") {
                $self->warn( qq{$val passed as '$key' is a regex} );
                delete $parms{$key};
                next;
            }
            if ($val =~ /^\s|\s$/) {
                $self->warn( qq{'$val' is space-padded and cannot succeed} );
                delete $parms{$key};
                next;
            }
        }
    } # for keys %parms

    my @links = $self->links or return;

    my @conditions;
    push @conditions, q/ $_[0]->[0] eq $parms{url} /                                if defined $parms{url};
    push @conditions, q/ $_[0]->[0] =~ $parms{url_regex} /                          if defined $parms{url_regex};
    push @conditions, q/ defined($_[0]->[1]) and $_[0]->[1] eq $parms{text} /       if defined $parms{text};
    push @conditions, q/ defined($_[0]->[1]) and $_[0]->[1] =~ $parms{text_regex} / if defined $parms{text_regex};
    push @conditions, q/ defined($_[0]->[2]) and $_[0]->[2] eq $parms{name} /       if defined $parms{name};
    push @conditions, q/ defined($_[0]->[2]) and $_[0]->[2] =~ $parms{name_regex} / if defined $parms{name_regex};
    push @conditions, q/ $_[0]->[3] and $_[0]->[3] eq $parms{tag} /                 if defined $parms{tag};
    push @conditions, q/ $_[0]->[3] and $_[0]->[3] =~ $parms{tag_regex} /           if defined $parms{tag_regex};

    my $matchfunc;
    if ( @conditions ) {
        local $" = ") && (";
        $matchfunc = eval "sub { return 1 if (@conditions); return; }";
    } else {
        $matchfunc = sub{1};
    }

    my $nmatches = 0;
    my @matches;
    for my $link ( @links ) {
        if ( $matchfunc->($link) ) {
            if ( $wantall ) {
                push( @matches, $link );
            } else {
                ++$nmatches;
                return $link if $nmatches >= $parms{n};
            }
        }
    } # for @links

    if ( $wantall ) {
        return @matches if wantarray;
        return \@matches;
    }

    return;
} # find_link

=head2 $mech->find_all_links( ... )

Returns all the links on the current page that match the criteria.  The
method for specifying link criteria is the same as in C<L<find_link()>>.
Each of the links returned is a L<WWW::Mechanize::Link> object.

In list context, C<find_all_links()> returns a list of the links.
Otherwise, it returns a reference to the list of links.

C<find_all_links()> with no parameters returns all links in the
page.

=cut

sub find_all_links {
    my $self = shift;
    return $self->find_link( @_, n=>'all' );
}


=head1 Miscellaneous methods

=head2 $mech->add_header(name => $value)

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

=head2 $mech->quiet(true/false)

Allows you to suppress warnings to the screen.

    $mech->quiet(0); # turns on warnings (the default)
    $mech->quiet(1); # turns off warnings
    $mech->quiet();  # returns the current quietness status

=cut

sub quiet {
    my $self = shift;

    $self->{quiet} = $_[0] if @_;

    return $self->{quiet};
}

=head1 Overridden L<LWP::UserAgent> methods

=head2 $mech->redirect_ok()

An overloaded version of C<redirect_ok()> in L<LWP::UserAgent>.
This method is used to determine whether a redirection in the request
should be followed.

=cut

sub redirect_ok {
    my $self = shift;
    my $prospective_request = shift;
    my $response = shift;

    my $ok = $self->SUPER::redirect_ok( $prospective_request, $response );
    if ( $ok ) {
        $self->{redirected_uri} = $prospective_request->uri;
    }

    return $ok;
}


=head2 $mech->request( $request [, $arg [, $size]])

Overloaded version of C<request()> in L<LWP::UserAgent>.  Performs
the actual request.  Normally, if you're using WWW::Mechanize, it'd
because you don't want to deal with this level of stuff anyway.

Note that C<$request> will be modified.

Returns an L<HTTP::Response> object.

=cut

sub request {
    my $self = shift;
    my $request = shift;

    if ( $request->method eq "GET" || $request->method eq "POST" ) {
        $self->_push_page_stack();
    }

    $request->header( Referer => $self->{last_uri} ) if $self->{last_uri};
    while ( my($key,$value) = each %WWW::Mechanize::headers ) {
        $request->header( $key => $value );
    }
    $self->{req} = $request;
    $self->{redirected_uri} = $request->uri->as_string;

    # add correct Accept-Encoding header to restore compliance with
    # http://www.freesoft.org/CIE/RFC/2068/158.htm
    unless ($request->header('Accept-Encoding')) {
        my $accept = 'identity';
        # only allow "identity" for the time being
        #eval {
        #  require Compress::Zlib;
        #  $accept .= ', deflate, gzip';
        #};
        $self->add_header( 'Accept-Encoding', $accept);
    };

    my $res = $self->{res} = $self->_make_request( $request, @_ );

    # These internal hash elements should be dropped in favor of
    # the accessors soon. -- 1/19/03
    $self->{status}  = $res->code;
    $self->{base}    = $res->base;
    $self->{ct}      = $res->content_type || "";
    $self->{content} = $res->content;

    # decode any gzipped/compressed response
    # (currently isn't reached because we only allow 'identity')
    my $encoding = $res->header('Content-Encoding') || "";
    if ($encoding =~ /^(?:gzip|deflate)$/) {
        $self->{content} = Compress::Zlib::memGunzip( $self->{content});
        # should I delete the response header?
    };

    if ( $self->{res}->is_success ) {
        $self->{uri} = $self->{redirected_uri};
        $self->{last_uri} = $self->{uri};
    } else {
        if ( $self->{autocheck} ) {
            $self->die( "Error ", $request->method, "ing ", $request->uri, ": ", $res->message );
        }
    }

    $self->_reset_page();
    $self->_parse_html if $self->is_html;

    return $res;
} # request

=head2 $mech->_parse_html()

An internal method that initializes forms and links given a HTML document.
If you need to override this in your subclass, or call it multiple times,
go ahead.

=cut

sub _parse_html {
    my $self = shift;
    $self->{forms} = [ HTML::Form->parse($self->content, $self->base) ];
    $self->{form}  = $self->{forms}->[0];
    $self->_extract_links();
}


=head2 $mech->_make_request()

Convenience method to make it easier for subclasses like
L<WWW::Mechanize::Cached> to intercept the request.

=cut

sub _make_request {
    my $self = shift;
    $self->SUPER::request(@_);
}

=head1 Deprecated methods

This methods have been replaced by more flexible and precise methods.
Please use them instead.

=head2 $mech->follow($string|$num)

B<DEPRECATED> in favor of C<L<follow_link()>>, which provides more
flexibility.

Follow a link.  If you provide a string, the first link whose text
matches that string will be followed.  If you provide a number, it
will be the I<$num>th link on the page.  Note that the links are
0-based.

Returns true if the link was found on the page or undef otherwise.

=cut

sub follow {
    my ($self, $link) = @_;
    my @links = $self->links;
    my $thislink;
    if ( $link =~ /^\d+$/ ) { # is a number?
        if ($link <= $#links) {
            $thislink = $links[$link];
        } else {
            $self->warn( "Link number $link is greater than maximum link $#links on this page ($self->{uri})" );
            return;
        }
    } else {                        # user provided a regexp
        LINK: foreach my $l (@links) {
            if ( defined($l->[1]) && $l->[1] =~ /$link/) {
                $thislink = $l;     # grab first match
                last LINK;
            }
        }
        unless ($thislink) {
            $self->warn( "Can't find any link matching $link on this page ($self->{uri})" );
            return;
        }
    }

    $thislink = $thislink->[0];     # we just want the URL, not the text

    $self->get( $thislink );

    return 1;
}

=head2 $mech->form($number|$name)

B<DEPRECATED> in favor of C<L<form_name()>> or C<L<form_number()>>.

Selects a form by number or name, depending on if it gets passed an
all-numeric string or not.  This means that if you have a form name
that's all digits, this method will not do the right thing.

=cut

sub form {
    my $self = shift;
    my $arg = shift;

    return $arg =~ /^\d+$/ ? $self->form_number($arg) : $self->form_name($arg);
}

=head1 Internal-only methods

These methods are only used internally.  You probably don't need to
know about them.

=head2 $mech->_reset_page()

Resets the internal fields that track page parsed stuff.

=cut

sub _reset_page {
    my $self = shift;

    $self->{links} = [];
    delete $self->{title};
    $self->{forms} = [];
    delete $self->{form};

    return;
}

=head2 $mech->_extract_links()

Extracts links from the content of a webpage, and populates the C<{links}>
property with L<WWW::Mechanize::Link> objects.

=cut

my %urltags = (
    a => "href",
    area => "href",
    frame => "src",
    iframe => "src",
    meta => "content",
);

sub _extract_links {
    require WWW::Mechanize::Link;

    my $self = shift;

    my $p = HTML::TokeParser->new(\$self->{content});

    $self->{links} = [];

    while (my $token = $p->get_tag( keys %urltags )) {
        my $tag = $token->[0];
        my $url = $token->[1]{$urltags{$tag}};

        my $text;
        my $name;
        if ( $tag eq "a" ) {
            $text = $p->get_trimmed_text("/$tag");
            $text = "" unless defined $text;

            my $onClick = $token->[1]{onclick};
            if ( $onClick && ($onClick =~ /^window\.open\(\s*'([^']+)'/) ) {
                $url = $1;
            }
        } # a
        if ( $tag ne "area" ) {
            $name = $token->[1]{name};
        }
        if ( $tag eq "meta" ) {
            my $equiv = $token->[1]{"http-equiv"};
            my $content = $token->[1]{"content"};
            next unless $equiv && (lc $equiv eq "refresh") && defined $content;

            if ( $content =~ /^\d+\s*;\s*url\s*=\s*(.+)/ ) {
                $url = $1;
            } else {
                undef $url;
            }
        } # meta

        next unless defined $url;   # probably just a name link or <AREA NOHREF...>
        push( @{$self->{links}}, WWW::Mechanize::Link->new( $url, $text, $name, $tag, $self->base ) );
    } # while

    # Old extract_links() returned a value.  Carp if someone expects
    # this version to return something.
    if ( defined wantarray ) {
        my $func = (caller(0))[3];
        $self->warn( "$func does not return a useful value" );
    }

    return;
}

=head2 $mech->_push_page_stack() / $mech->_pop_page_stack()

The agent keeps a stack of visited pages, which it can pop when it needs
to go BACK and so on.

The current page needs to be pushed onto the stack before we get a new
page, and the stack needs to be popped when BACK occurs.

Neither of these take any arguments, they just operate on the $mech
object.

=cut

sub _push_page_stack {
    my $self = shift;

    # Don't push anything if it's a virgin object
    if ( $self->{res} ) {
        my $save_stack = $self->{page_stack};
        $self->{page_stack} = [];

        push( @$save_stack, $self->clone );

        $self->{page_stack} = $save_stack;
    }

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

=head2 warn( @messages )

Centralized warning method, for diagnostics and non-fatal problems.
Defaults to calling C<CORE::warn>, but may be overridden by setting
C<onwarn> in the construcotr.

=cut

sub warn {
    my $self = shift;

    return unless my $handler = $self->{onwarn};

    return if $self->quiet;

    $handler->(@_);
}

=head2 die( @messages )

Centralized error method.  Defaults to calling C<CORE::die>, but
may be overridden by setting C<onerror> in the construcotr.

=cut

sub die {
    my $self = shift;

    return unless my $handler = $self->{onerror};

    $handler->(@_);
}


# NOT an object method!
sub _warn {
    require Carp;
    &Carp::carp; # pass thru
}

# NOT an object method!
sub _die {
    require Carp;
    &Carp::croak; # pass thru
}

=head1 OTHER DOCUMENTATION

=head2 I<Spidering Hacks>, by Kevin Hemenway and Tara Calishain

I<Spidering Hacks> from O'Reilly
(L<http://www.oreilly.com/catalog/spiderhks/>) is a great book for anyone
wanting to know more about screen-scraping and spidering.

There are six hacks that use Mech or a Mech derivative:

=over 4

=item #21 WWW::Mechanize 101

=item #22 Scraping with WWW::Mechanize

=item #36 Downloading Images from Webshots

=item #44 Archiving Yahoo! Groups Messages with WWW::Yahoo::Groups

=item #64 Super Author Searching

=item #73 Scraping TV Listings

=back

The book was also positively reviewed on Slashdot:
L<http://books.slashdot.org/article.pl?sid=03/12/11/2126256>

=head2 Online resources

=over 4

=item * WWW::Mechanize Development mailing list

Hosted at Sourceforge, this is where the contributors to Mech
discuss things.  L<http://sourceforge.net/mail/?group_id=83309>

=item * LWP mailing list

The LWP mailing list is at
L<http://lists.perl.org/showlist.cgi?name=libwww>, and is more
user-oriented and well-populated than the WWW::Mechanize Development
list.  This is a good list for Mech users, since LWP is the basis
for Mech.

=item * L<WWW::Mechanize::Examples>

A random array of examples submitted by users, included with the
Mechanize distribution.

=item * L<http://www.perl.com/pub/a/2003/01/22/mechanize.html>

Chris Ball's article about using WWW::Mechanize for scraping TV
listings.

=item * L<http://www.stonehenge.com/merlyn/LinuxMag/col47.html>

Randal Schwartz's article on scraping Yahoo News for images.  It's
already out of date: He manually walks the list of links hunting
for matches, which wouldn't have been necessary if the C<find_link()>
method existed at press time.

=item * L<http://www.perladvent.org/2002/16th/>

WWW::Mechanize on the Perl Advent Calendar, by Mark Fowler.

=item * L<http://www.linux-magazin.de/Artikel/ausgabe/2004/03/perl/perl.html>

Michael Schilli's article on Mech and L<WWW::Mechanize::Shell> for the
German magazine I<Linux Magazin>.

=back

=head2 Other modules that use Mechanize

Here are modules that use or subclass Mechanize.  Let me know of any others:

=over 4

=item * L<WWW::Bugzilla>

=item * L<WWW::Google::Groups>

=item * L<WWW::Mechanize::Cached>

=item * L<WWW::Mechanize::FormFiller>

=item * L<WWW::Mechanize::Shell>

=item * L<WWW::Mechanize::Sleepy>

=item * L<WWW::Mechanize::SpamCop>

=item * L<WWW::Mechanize::Timed>

=item * L<WWW::SourceForge>

=item * L<WWW::Yahoo::Groups>

=back

=head1 Requests & Bugs

Please report any requests, suggestions or (gasp!) bugs via the
excellent RT bug-tracking system at http://rt.cpan.org/, or email to
bug-WWW-Mechanize@rt.cpan.org.  This makes it much easier for me to
track things.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize> is the RT queue
for Mechanize.  Please check to see if your bug has already been reported.

=head1 Author

Copyright 2004 Andy Lester <andy@petdance.com>

Released under the Artistic License.  Based on Kirrily Robert's excellent
L<WWW::Automate> package.

=cut

1;
