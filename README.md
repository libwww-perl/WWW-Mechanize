# NAME

WWW::Mechanize - Handy web browsing in a Perl object

[![Build Status](https://travis-ci.org/libwww-perl/WWW-Mechanize.png?branch=master)](https://travis-ci.org/libwww-perl/WWW-Mechanize)

# VERSION

version 1.91

# SYNOPSIS

WWW::Mechanize supports performing a sequence of page fetches including
following links and submitting forms. Each fetched page is parsed
and its links and forms are extracted. A link or a form can be
selected, form fields can be filled and the next page can be fetched.
Mech also stores a history of the URLs you've visited, which can
be queried and revisited.

    use WWW::Mechanize ();
    my $mech = WWW::Mechanize->new();

    $mech->get( $url );

    $mech->follow_link( n => 3 );
    $mech->follow_link( text_regex => qr/download this/i );
    $mech->follow_link( url => 'http://host.com/index.html' );

    $mech->submit_form(
        form_number => 3,
        fields      => {
            username    => 'mungo',
            password    => 'lost-and-alone',
        }
    );

    $mech->submit_form(
        form_name => 'search',
        fields    => { query  => 'pot of gold', },
        button    => 'Search Now'
    );

    # Enable strict form processing to catch typos and non-existant form fields.
    my $strict_mech = WWW::Mechanize->new( strict_forms => 1);

    $strict_mech->get( $url );

    # This method call will die, saving you lots of time looking for the bug.
    $strict_mech->submit_form(
        form_number => 3,
        fields      => {
            usernaem     => 'mungo',           # typo in field name
            password     => 'lost-and-alone',
            extra_field  => 123,               # field does not exist
        }
    );

# DESCRIPTION

`WWW::Mechanize`, or Mech for short, is a Perl module for stateful
programmatic web browsing, used for automating interaction with
websites.

Features include:

- All HTTP methods
- High-level hyperlink and HTML form support, without having to parse HTML yourself
- SSL support
- Automatic cookies
- Custom HTTP headers
- Automatic handling of redirections
- Proxies
- HTTP authentication

Mech is well suited for use in testing web applications.  If you use
one of the Test::\*, like [Test::HTML::Lint](https://metacpan.org/pod/Test::HTML::Lint) modules, you can check the
fetched content and use that as input to a test call.

    use Test::More;
    like( $mech->content(), qr/$expected/, "Got expected content" );

Each page fetch stores its URL in a history stack which you can
traverse.

    $mech->back();

If you want finer control over your page fetching, you can use
these methods. `follow_link` and `submit_form` are just high
level wrappers around them.

    $mech->find_link( n => $number );
    $mech->form_number( $number );
    $mech->form_name( $name );
    $mech->field( $name, $value );
    $mech->set_fields( %field_values );
    $mech->set_visible( @criteria );
    $mech->click( $button );

[WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize) is a proper subclass of [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) and
you can also use any of [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)'s methods.

    $mech->add_header($name => $value);

Please note that Mech does NOT support JavaScript, you need additional software
for that. Please check ["JavaScript" in WWW::Mechanize::FAQ](https://metacpan.org/pod/WWW::Mechanize::FAQ#JavaScript) for more.

# IMPORTANT LINKS

- [https://github.com/libwww-perl/WWW-Mechanize/issues](https://github.com/libwww-perl/WWW-Mechanize/issues)

    The queue for bugs & enhancements in WWW::Mechanize.  Please note that the
    queue at [http://rt.cpan.org](http://rt.cpan.org) is no longer maintained.

- [https://metacpan.org/pod/WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize)

    The CPAN documentation page for Mechanize.

- [https://metacpan.org/pod/distribution/WWW-Mechanize/lib/WWW/Mechanize/FAQ.pod](https://metacpan.org/pod/distribution/WWW-Mechanize/lib/WWW/Mechanize/FAQ.pod)

    Frequently asked questions.  Make sure you read here FIRST.

# CONSTRUCTOR AND STARTUP

## new()

Creates and returns a new WWW::Mechanize object, hereafter referred to as
the "agent".

    my $mech = WWW::Mechanize->new()

The constructor for WWW::Mechanize overrides two of the parms to the
LWP::UserAgent constructor:

    agent => 'WWW-Mechanize/#.##'
    cookie_jar => {}    # an empty, memory-only HTTP::Cookies object

You can override these overrides by passing parms to the constructor,
as in:

    my $mech = WWW::Mechanize->new( agent => 'wonderbot 1.01' );

If you want none of the overhead of a cookie jar, or don't want your
bot accepting cookies, you have to explicitly disallow it, like so:

    my $mech = WWW::Mechanize->new( cookie_jar => undef );

Here are the parms that WWW::Mechanize recognizes.  These do not include
parms that [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) recognizes.

- `autocheck => [0|1]`

    Checks each request made to see if it was successful.  This saves
    you the trouble of manually checking yourself.  Any errors found
    are errors, not warnings.

    The default value is ON, unless it's being subclassed, in which
    case it is OFF.  This means that standalone [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize) instances
    have autocheck turned on, which is protective for the vast majority
    of Mech users who don't bother checking the return value of get()
    and post() and can't figure why their code fails. However, if
    [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize) is subclassed, such as for [Test::WWW::Mechanize](https://metacpan.org/pod/Test::WWW::Mechanize)
    or [Test::WWW::Mechanize::Catalyst](https://metacpan.org/pod/Test::WWW::Mechanize::Catalyst), this may not be an appropriate
    default, so it's off.

- `noproxy => [0|1]`

    Turn off the automatic call to the [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) `env_proxy` function.

    This needs to be explicitly turned off if you're using [Crypt::SSLeay](https://metacpan.org/pod/Crypt::SSLeay) to
    access a https site via a proxy server.  Note: you still need to set your
    HTTPS\_PROXY environment variable as appropriate.

- `onwarn => \&func`

    Reference to a `warn`-compatible function, such as `[Carp](https://metacpan.org/pod/Carp)::carp`,
    that is called when a warning needs to be shown.

    If this is set to `undef`, no warnings will ever be shown.  However,
    it's probably better to use the `quiet` method to control that behavior.

    If this value is not passed, Mech uses `Carp::carp` if [Carp](https://metacpan.org/pod/Carp) is
    installed, or `CORE::warn` if not.

- `onerror => \&func`

    Reference to a `die`-compatible function, such as `[Carp](https://metacpan.org/pod/Carp)::croak`,
    that is called when there's a fatal error.

    If this is set to `undef`, no errors will ever be shown.

    If this value is not passed, Mech uses `Carp::croak` if [Carp](https://metacpan.org/pod/Carp) is
    installed, or `CORE::die` if not.

- `quiet => [0|1]`

    Don't complain on warnings.  Setting `quiet => 1` is the same as
    calling `$mech->quiet(1)`.  Default is off.

- `stack_depth => $value`

    Sets the depth of the page stack that keeps track of all the
    downloaded pages. Default is effectively infinite stack size.  If
    the stack is eating up your memory, then set this to a smaller
    number, say 5 or 10.  Setting this to zero means Mech will keep no
    history.

In addition, WWW::Mechanize also allows you to globally enable
strict and verbose mode for form handling, which is done with [HTML::Form](https://metacpan.org/pod/HTML::Form).

- `strict_forms => [0|1]`

    Globally sets the HTML::Form strict flag which causes form submission to
    croak if any of the passed fields don't exist in the form, and/or a value
    doesn't exist in a select element. This can still be disabled in individual
    calls to [`submit_form()|"$mech->submit_form( ... )"`](https://metacpan.org/pod/submit_form\(\)|&#x22;$mech->submit_form\(&#x20;...&#x20;\)&#x22;).

    Default is off.

- `verbose_forms => [0|1]`

    Globally sets the HTML::Form verbose flag which causes form submission to
    warn about any bad HTML form constructs found. This cannot be disabled
    later.

    Default is off.

To support forms, WWW::Mechanize's constructor pushes POST
on to the agent's `requests_redirectable` list (see also
[LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent).)

## $mech->agent\_alias( $alias )

Sets the user agent string to the expanded version from a table of actual user strings.
_$alias_ can be one of the following:

- Windows IE 6
- Windows Mozilla
- Mac Safari
- Mac Mozilla
- Linux Mozilla
- Linux Konqueror

then it will be replaced with a more interesting one.  For instance,

    $mech->agent_alias( 'Windows IE 6' );

sets your User-Agent to

    Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)

The list of valid aliases can be returned from `known_agent_aliases()`.  The current list is:

- Windows IE 6
- Windows Mozilla
- Mac Safari
- Mac Mozilla
- Linux Mozilla
- Linux Konqueror

## known\_agent\_aliases()

Returns a list of all the agent aliases that Mech knows about.

# PAGE-FETCHING METHODS

## $mech->get( $uri )

Given a URL/URI, fetches it.  Returns an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object.
_$uri_ can be a well-formed URL string, a [URI](https://metacpan.org/pod/URI) object, or a
[WWW::Mechanize::Link](https://metacpan.org/pod/WWW::Mechanize::Link) object.

The results are stored internally in the agent object, but you don't
know that.  Just use the accessors listed below.  Poking at the
internals is deprecated and subject to change in the future.

`get()` is a well-behaved overloaded version of the method in
[LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent).  This lets you do things like

    $mech->get( $uri, ':content_file' => $tempfile );

and you can rest assured that the parms will get filtered down
appropriately.

**NOTE:** Because `:content_file` causes the page contents to be
stored in a file instead of the response object, some Mech functions
that expect it to be there won't work as expected. Use with caution.

## $mech->post( $uri, content => $content )

POSTs _$content_ to $uri.  Returns an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object.
_$uri_ can be a well-formed URI string, a [URI](https://metacpan.org/pod/URI) object, or a
[WWW::Mechanize::Link](https://metacpan.org/pod/WWW::Mechanize::Link) object.

## $mech->put( $uri, content => $content )

PUTs _$content_ to $uri.  Returns an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object.
_$uri_ can be a well-formed URI string, a [URI](https://metacpan.org/pod/URI) object, or a
[WWW::Mechanize::Link](https://metacpan.org/pod/WWW::Mechanize::Link) object.

## $mech->reload()

Acts like the reload button in a browser: repeats the current
request. The history (as per the [back()](#mech-back) method) is not altered.

Returns the [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object from the reload, or `undef`
if there's no current request.

## $mech->back()

The equivalent of hitting the "back" button in a browser.  Returns to
the previous page.  Won't go back past the first page. (Really, what
would it do if it could?)

Returns true if it could go back, or false if not.

## $mech->clear\_history()

This deletes all the history entries and returns true.

## $mech->history\_count()

This returns the number of items in the browser history.  This number _does_
include the most recently made request.

## $mech->history($n)

This returns the _n_th item in history.  The 0th item is the most recent
request and response, which would be acted on by methods like
`[find_link()](#mech-find_link)`.
The 1th item is the state you'd return to if you called
`[back()](#mech-back)`.

The maximum useful value for `$n` is `$mech->history_count - 1`.
Requests beyond that bound will return `undef`.

History items are returned as hash references, in the form:

    { req => $http_request, res => $http_response }

# STATUS METHODS

## $mech->success()

Returns a boolean telling whether the last request was successful.
If there hasn't been an operation yet, returns false.

This is a convenience function that wraps `$mech->res->is_success`.

## $mech->uri()

Returns the current URI as a [URI](https://metacpan.org/pod/URI) object. This object stringifies
to the URI itself.

## $mech->response() / $mech->res()

Return the current response as an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object.

Synonym for `$mech->response()`

## $mech->status()

Returns the HTTP status code of the response.  This is a 3-digit
number like 200 for OK, 404 for not found, and so on.

## $mech->ct() / $mech->content\_type()

Returns the content type of the response.

## $mech->base()

Returns the base URI for the current response

## $mech->forms()

When called in a list context, returns a list of the forms found in
the last fetched page. In a scalar context, returns a reference to
an array with those forms. The forms returned are all [HTML::Form](https://metacpan.org/pod/HTML::Form)
objects.

## $mech->current\_form()

Returns the current form as an [HTML::Form](https://metacpan.org/pod/HTML::Form) object.

## $mech->links()

When called in a list context, returns a list of the links found in the
last fetched page.  In a scalar context it returns a reference to an array
with those links.  Each link is a [WWW::Mechanize::Link](https://metacpan.org/pod/WWW::Mechanize::Link) object.

## $mech->is\_html()

Returns true/false on whether our content is HTML, according to the
HTTP headers.

## $mech->title()

Returns the contents of the `<TITLE>` tag, as parsed by
[HTML::HeadParser](https://metacpan.org/pod/HTML::HeadParser).  Returns undef if the content is not HTML.

# CONTENT-HANDLING METHODS

## $mech->content(...)

Returns the content that the mech uses internally for the last page
fetched. Ordinarily this is the same as
`$mech->response()->decoded_content()`,
but this may differ for HTML documents if [update\_html](#mech-update_html-html) is
overloaded (in which case the value passed to the base-class
implementation of same will be returned), and/or extra named arguments
are passed to _content()_:

- _$mech->content( format => 'text' )_

    Returns a text-only version of the page, with all HTML markup
    stripped. This feature requires _HTML::TreeBuilder_ version 5 or higher
    to be installed, or a fatal error will be thrown. This works only if
    the contents are HTML.

- _$mech->content( base\_href => \[$base\_href|undef\] )_

    Returns the HTML document, modified to contain a
    `<base href="$base_href">` mark-up in the header.
    _$base\_href_ is `$mech->base()` if not specified. This is
    handy to pass the HTML to e.g. [HTML::Display](https://metacpan.org/pod/HTML::Display). This works only if
    the contents are HTML.

- _$mech->content( raw => 1 )_

    Returns `$self->response()->content()`, i.e. the raw contents from the
    response.

- _$mech->content( decoded\_by\_headers => 1 )_

    Returns the content after applying all `Content-Encoding` headers but
    with not additional mangling.

- _$mech->content( charset => $charset )_

    Returns `$self->response()->decoded_content(charset => $charset)`
    (see [HTTP::Response](https://metacpan.org/pod/HTTP::Response) for details).

To preserve backwards compatibility, additional parameters will be
ignored unless none of `raw | decoded_by_headers | charset` is
specified and the text is HTML, in which case an error will be triggered.

## $mech->text()

Returns the text of the current HTML content.  If the content isn't
HTML, `$mech` will die.

The text is extracted by parsing the content, and then the extracted
text is cached, so don't worry about performance of calling this
repeatedly.

# LINK METHODS

## $mech->links()

Lists all the links on the current page.  Each link is a
WWW::Mechanize::Link object. In list context, returns a list of all
links.  In scalar context, returns an array reference of all links.

## $mech->follow\_link(...)

Follows a specified link on the page.  You specify the match to be
found using the same parms that `[find_link()](#mech-find_link)` uses.

Here some examples:

- 3rd link called "download"

        $mech->follow_link( text => 'download', n => 3 );

- first link where the URL has "download" in it, regardless of case:

        $mech->follow_link( url_regex => qr/download/i );

    or

        $mech->follow_link( url_regex => qr/(?i:download)/ );

- 3rd link on the page

        $mech->follow_link( n => 3 );

- the link with the url

        $mech->follow_link( url => '/other/page' );

    or

        $mech->follow_link( url => 'http://example.com/page' );

Returns the result of the GET method (an HTTP::Response object) if
a link was found. If the page has no links, or the specified link
couldn't be found, returns undef.

## $mech->find\_link( ... )

Finds a link in the currently fetched page. It returns a
[WWW::Mechanize::Link](https://metacpan.org/pod/WWW::Mechanize::Link) object which describes the link.  (You'll
probably be most interested in the `url()` property.)  If it fails
to find a link it returns undef.

You can take the URL part and pass it to the `get()` method.  If
that's your plan, you might as well use the `follow_link()` method
directly, since it does the `get()` for you automatically.

Note that `<FRAME SRC="...">` tags are parsed out of the the HTML
and treated as links so this method works with them.

You can select which link to find by passing in one or more of these
key/value pairs:

- `text => 'string',` and `text_regex => qr/regex/,`

    `text` matches the text of the link against _string_, which must be an
    exact match.  To select a link with text that is exactly "download", use

        $mech->find_link( text => 'download' );

    `text_regex` matches the text of the link against _regex_.  To select a
    link with text that has "download" anywhere in it, regardless of case, use

        $mech->find_link( text_regex => qr/download/i );

    Note that the text extracted from the page's links are trimmed.  For
    example, `<a> foo </a>` is stored as 'foo', and searching for
    leading or trailing spaces will fail.

- `url => 'string',` and `url_regex => qr/regex/,`

    Matches the URL of the link against _string_ or _regex_, as appropriate.
    The URL may be a relative URL, like `foo/bar.html`, depending on how
    it's coded on the page.

- `url_abs => string` and `url_abs_regex => regex`

    Matches the absolute URL of the link against _string_ or _regex_,
    as appropriate.  The URL will be an absolute URL, even if it's relative
    in the page.

- `name => string` and `name_regex => regex`

    Matches the name of the link against _string_ or _regex_, as appropriate.

- `id => string` and `id_regex => regex`

    Matches the attribute 'id' of the link against _string_ or
    _regex_, as appropriate.

- `class => string` and `class_regex => regex`

    Matches the attribute 'class' of the link against _string_ or
    _regex_, as appropriate.

- `tag => string` and `tag_regex => regex`

    Matches the tag that the link came from against _string_ or _regex_,
    as appropriate.  The `tag_regex` is probably most useful to check for
    more than one tag, as in:

        $mech->find_link( tag_regex => qr/^(a|frame)$/ );

    The tags and attributes looked at are defined below.

If `n` is not specified, it defaults to 1.  Therefore, if you don't
specify any parms, this method defaults to finding the first link on the
page.

Note that you can specify multiple text or URL parameters, which
will be ANDed together.  For example, to find the first link with
text of "News" and with "cnn.com" in the URL, use:

    $mech->find_link( text => 'News', url_regex => qr/cnn\.com/ );

The return value is a reference to an array containing a
[WWW::Mechanize::Link](https://metacpan.org/pod/WWW::Mechanize::Link) object for every link in `$self->content`.

The links come from the following:

- `<a href=...>`
- `<area href=...>`
- `<frame src=...>`
- `<iframe src=...>`
- `<link href=...>`
- `<meta content=...>`

## $mech->find\_all\_links( ... )

Returns all the links on the current page that match the criteria.  The
method for specifying link criteria is the same as in
`[find_link()](#mech-find_link)`.
Each of the links returned is a [WWW::Mechanize::Link](https://metacpan.org/pod/WWW::Mechanize::Link) object.

In list context, `find_all_links()` returns a list of the links.
Otherwise, it returns a reference to the list of links.

`find_all_links()` with no parameters returns all links in the
page.

## $mech->find\_all\_inputs( ... criteria ... )

find\_all\_inputs() returns an array of all the input controls in the
current form whose properties match all of the regexes passed in.
The controls returned are all descended from HTML::Form::Input.
See ["INPUTS" in HTML::Form](https://metacpan.org/pod/HTML::Form#INPUTS) for details.

If no criteria are passed, all inputs will be returned.

If there is no current page, there is no form on the current
page, or there are no submit controls in the current form
then the return will be an empty array.

You may use a regex or a literal string:

    # get all textarea controls whose names begin with "customer"
    my @customer_text_inputs = $mech->find_all_inputs(
        type       => 'textarea',
        name_regex => qr/^customer/,
    );

    # get all text or textarea controls called "customer"
    my @customer_text_inputs = $mech->find_all_inputs(
        type_regex => qr/^(text|textarea)$/,
        name       => 'customer',
    );

## $mech->find\_all\_submits( ... criteria ... )

`find_all_submits()` does the same thing as `find_all_inputs()`
except that it only returns controls that are submit controls,
ignoring other types of input controls like text and checkboxes.

# IMAGE METHODS

## $mech->images

Lists all the images on the current page.  Each image is a
WWW::Mechanize::Image object. In list context, returns a list of all
images.  In scalar context, returns an array reference of all images.

## $mech->find\_image()

Finds an image in the current page. It returns a
[WWW::Mechanize::Image](https://metacpan.org/pod/WWW::Mechanize::Image) object which describes the image.  If it fails
to find an image it returns undef.

You can select which image to find by passing in one or more of these
key/value pairs:

- `alt => 'string'` and `alt_regex => qr/regex/`

    `alt` matches the ALT attribute of the image against _string_, which must be an
    exact match. To select a image with an ALT tag that is exactly "download", use

        $mech->find_image( alt => 'download' );

    `alt_regex` matches the ALT attribute of the image  against a regular
    expression.  To select an image with an ALT attribute that has "download"
    anywhere in it, regardless of case, use

        $mech->find_image( alt_regex => qr/download/i );

- `url => 'string'` and `url_regex => qr/regex/`

    Matches the URL of the image against _string_ or _regex_, as appropriate.
    The URL may be a relative URL, like `foo/bar.html`, depending on how
    it's coded on the page.

- `url_abs => string` and `url_abs_regex => regex`

    Matches the absolute URL of the image against _string_ or _regex_,
    as appropriate.  The URL will be an absolute URL, even if it's relative
    in the page.

- `tag => string` and `tag_regex => regex`

    Matches the tag that the image came from against _string_ or _regex_,
    as appropriate.  The `tag_regex` is probably most useful to check for
    more than one tag, as in:

        $mech->find_image( tag_regex => qr/^(img|input)$/ );

    The tags supported are `<img>` and `<input>`.

- `id => string` and `id_regex => regex`

    `id` matches the id attribute of the image against _string_, which must
    be an exact match. To select an image with the exact id "download-image", use

        $mech->find_image( id => 'download-image' );

    `id_regex` matches the id attribute of the image against a regular
    expression. To select the first image with an id that contains "download"
    anywhere in it, use

        $mech->find_image( id_regex => qr/download/ );

- `classs => string` and `class_regex => regex`

    `class` matches the class attribute of the image against _string_, which must
    be an exact match. To select an image with the exact class "img-fuid", use

        $mech->find_image( class => 'img-fluid' );

    To select an image with the class attribute "rounded float-left", use

        $mech->find_image( class => 'rounded float-left' );

    Note that the classes have to be matched as a complete string, in the exact
    order they appear in the website's source code.

    `class_regex` matches the class attribute of the image against a regular
    expression. Use this if you want a partial class name, or if an image has
    several classes, but you only care about one.

    To select the first image with the class "rounded", where there are multiple
    images that might also have either class "float-left" or "float-right", use

        $mech->find_image( class_regex => qr/\brounded\b/ );

    Selecting an image with multiple classes where you do not care about the
    order they appear in the website's source code is not currently supported.

If `n` is not specified, it defaults to 1.  Therefore, if you don't
specify any parms, this method defaults to finding the first image on the
page.

Note that you can specify multiple ALT or URL parameters, which
will be ANDed together.  For example, to find the first image with
ALT text of "News" and with "cnn.com" in the URL, use:

    $mech->find_image( image => 'News', url_regex => qr/cnn\.com/ );

The return value is a reference to an array containing a
[WWW::Mechanize::Image](https://metacpan.org/pod/WWW::Mechanize::Image) object for every image in `$self->content`.

## $mech->find\_all\_images( ... )

Returns all the images on the current page that match the criteria.  The
method for specifying image criteria is the same as in
`[find_image()](#mech-find_image)`.
Each of the images returned is a [WWW::Mechanize::Image](https://metacpan.org/pod/WWW::Mechanize::Image) object.

In list context, `find_all_images()` returns a list of the images.
Otherwise, it returns a reference to the list of images.

`find_all_images()` with no parameters returns all images in the page.

# FORM METHODS

These methods let you work with the forms on a page.  The idea is
to choose a form that you'll later work with using the field methods
below.

## $mech->forms

Lists all the forms on the current page.  Each form is an [HTML::Form](https://metacpan.org/pod/HTML::Form)
object.  In list context, returns a list of all forms.  In scalar
context, returns an array reference of all forms.

## $mech->form\_number($number)

Selects the _number_th form on the page as the target for subsequent
calls to `[field()](#mech-field-name-value-number)`
and `[click()](#mech-click-button-x-y)`.
Also returns the form that was selected.

If it is found, the form is returned as an [HTML::Form](https://metacpan.org/pod/HTML::Form) object and set internally
for later use with Mech's form methods such as
`[field()](#mech-field-name-value-number)` and
`[click()](#mech-click-button-x-y)`.
When called in a list context, the number of the found form is also returned as
a second value.

Emits a warning and returns undef if no form is found.

The first form is number 1, not zero.

## $mech->form\_name( $name )

Selects a form by name.  If there is more than one form on the page
with that name, then the first one is used, and a warning is
generated.

If it is found, the form is returned as an [HTML::Form](https://metacpan.org/pod/HTML::Form) object and
set internally for later use with Mech's form methods such as
`[field()](#mech-field-name-value-number)` and
`[click()](#mech-click-button-x-y)`.

Returns undef if no form is found.

## $mech->form\_id( $name )

Selects a form by ID.  If there is more than one form on the page
with that ID, then the first one is used, and a warning is generated.

If it is found, the form is returned as an [HTML::Form](https://metacpan.org/pod/HTML::Form) object and
set internally for later use with Mech's form methods such as
`[field()](#mech-field-name-value-number)` and
`[click()](#mech-click-button-x-y)`.

If no form is found it returns `undef`.  This will also trigger a warning,
unless `quiet` is enabled.

## $mech->all\_forms\_with\_fields( @fields )

Selects a form by passing in a list of field names it must contain.  All matching forms (perhaps none) are returned as a list of [HTML::Form](https://metacpan.org/pod/HTML::Form) objects.

## $mech->form\_with\_fields( @fields )

Selects a form by passing in a list of field names it must contain.  If there
is more than one form on the page with that matches, then the first one is used,
and a warning is generated.

If it is found, the form is returned as an [HTML::Form](https://metacpan.org/pod/HTML::Form) object and set internally
for later used with Mech's form methods such as
`[field()](#mech-field-name-value-number)` and
`[click()](#mech-click-button-x-y)`.

Returns undef and emits a warning if no form is found.

Note that this functionality requires libwww-perl 5.69 or higher.

## $mech->all\_forms\_with( $attr1 => $value1, $attr2 => $value2, ... )

Searches for forms with arbitrary attribute/value pairs within the &lt;form>
tag.
(Currently does not work for attribute `action` due to implementation details
of [HTML::Form](https://metacpan.org/pod/HTML::Form).)
When given more than one pair, all criteria must match.
Using `undef` as value means that the attribute in question may not be present.

All matching forms (perhaps none) are returned as a list of [HTML::Form](https://metacpan.org/pod/HTML::Form) objects.

## $mech->form\_with( $attr1 => $value1, $attr2 => $value2, ... )

Searches for forms with arbitrary attribute/value pairs within the &lt;form>
tag.
(Currently does not work for attribute `action` due to implementation details
of [HTML::Form](https://metacpan.org/pod/HTML::Form).)
When given more than one pair, all criteria must match.
Using `undef` as value means that the attribute in question may not be present.

If it is found, the form is returned as an [HTML::Form](https://metacpan.org/pod/HTML::Form) object and set internally
for later used with Mech's form methods such as
`[field()](#mech-field-name-value-number)` and
`[click()](#mech-click-button-x-y)`.

Returns undef if no form is found.

# FIELD METHODS

These methods allow you to set the values of fields in a given form.

## $mech->field( $name, $value, $number )

## $mech->field( $name, \\@values, $number )

Given the name of a field, set its value to the value specified.
This applies to the current form (as set by the
`[form_name()](#mech-form_name-name)` or
`[form_number()](#mech-form_number-number)`
method or defaulting to the first form on the page).

The optional _$number_ parameter is used to distinguish between two fields
with the same name.  The fields are numbered from 1.

## $mech->select($name, $value)

## $mech->select($name, \\@values)

Given the name of a `select` field, set its value to the value
specified.  If the field is not `<select multiple>` and the
`$value` is an array, only the **first** value will be set.  \[Note:
the documentation previously claimed that only the last value would
be set, but this was incorrect.\]  Passing `$value` as a hash with
an `n` key selects an item by number (e.g.
`{n => 3}` or `{n => [2,4]}`).
The numbering starts at 1.  This applies to the current form.

If you have a field with `<select multiple>` and you pass a single
`$value`, then `$value` will be added to the list of fields selected,
without clearing the others.  However, if you pass an array reference,
then all previously selected values will be cleared.

Returns true on successfully setting the value. On failure, returns
false and calls `$self->warn()` with an error message.

## $mech->set\_fields( $name => $value ... )

This method sets multiple fields of the current form. It takes a list
of field name and value pairs. If there is more than one field with
the same name, the first one found is set. If you want to select which
of the duplicate field to set, use a value which is an anonymous array
which has the field value and its number as the 2 elements.

        # set the second foo field
        $mech->set_fields( $name => [ 'foo', 2 ] );

The fields are numbered from 1.

This applies to the current form.

## $mech->set\_visible( @criteria )

This method sets fields of the current form without having to know
their names.  So if you have a login screen that wants a username and
password, you do not have to fetch the form and inspect the source (or
use the `mech-dump` utility, installed with WWW::Mechanize) to see
what the field names are; you can just say

    $mech->set_visible( $username, $password );

and the first and second fields will be set accordingly.  The method
is called set\__visible_ because it acts only on visible fields;
hidden form inputs are not considered.  The order of the fields is
the order in which they appear in the HTML source which is nearly
always the order anyone viewing the page would think they are in,
but some creative work with tables could change that; caveat user.

Each element in `@criteria` is either a field value or a field
specifier.  A field value is a scalar.  A field specifier allows
you to specify the _type_ of input field you want to set and is
denoted with an arrayref containing two elements.  So you could
specify the first radio button with

    $mech->set_visible( [ radio => 'KCRW' ] );

Field values and specifiers can be intermixed, hence

    $mech->set_visible( 'fred', 'secret', [ option => 'Checking' ] );

would set the first two fields to "fred" and "secret", and the _next_
`OPTION` menu field to "Checking".

The possible field specifier types are: "text", "password", "hidden",
"textarea", "file", "image", "submit", "radio", "checkbox" and "option".

`set_visible` returns the number of values set.

## $mech->tick( $name, $value \[, $set\] )

"Ticks" the first checkbox that has both the name and value associated
with it on the current form.  Dies if there is no named check box for
that value.  Passing in a false value as the third optional argument
will cause the checkbox to be unticked.

## $mech->untick($name, $value)

Causes the checkbox to be unticked.  Shorthand for
`tick($name,$value,undef)`

## $mech->value( $name \[, $number\] )

Given the name of a field, return its value. This applies to the current
form.

The optional _$number_ parameter is used to distinguish between two fields
with the same name.  The fields are numbered from 1.

If the field is of type file (file upload field), the value is always
cleared to prevent remote sites from downloading your local files.
To upload a file, specify its file name explicitly.

## $mech->click( $button \[, $x, $y\] )

Has the effect of clicking a button on the current form.  The first
argument is the name of the button to be clicked.  The second and
third arguments (optional) allow you to specify the (x,y) coordinates
of the click.

If there is only one button on the form, `$mech->click()` with
no arguments simply clicks that one button.

Returns an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object.

## $mech->click\_button( ... )

Has the effect of clicking a button on the current form by specifying
its name, value, or index.  Its arguments are a list of key/value
pairs.  Only one of name, number, input or value must be specified in
the keys.

- `name => name`

    Clicks the button named _name_ in the current form.

- `id => id`

    Clicks the button with the id _id_ in the current form.

- `number => n`

    Clicks the _n_th button in the current form. Numbering starts at 1.

- `value => value`

    Clicks the button with the value _value_ in the current form.

- `input => $inputobject`

    Clicks on the button referenced by $inputobject, an instance of
    [HTML::Form::SubmitInput](https://metacpan.org/pod/HTML::Form::SubmitInput) obtained e.g. from

        $mech->current_form()->find_input( undef, 'submit' )

    $inputobject must belong to the current form.

- `x => x`
- `y => y`

    These arguments (optional) allow you to specify the (x,y) coordinates
    of the click.

## $mech->submit()

Submits the current form, without specifying a button to click.  Actually,
no button is clicked at all.

Returns an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object.

This used to be a synonym for `$mech->click( 'submit' )`, but is no
longer so.

## $mech->submit\_form( ... )

This method lets you select a form from the previously fetched page,
fill in its fields, and submit it. It combines the `form_number`/`form_name`,
`set_fields` and `click` methods into one higher level call. Its arguments
are a list of key/value pairs, all of which are optional.

- `fields => \%fields`

    Specifies the fields to be filled in the current form.

- `with_fields => \%fields`

    Probably all you need for the common case. It combines a smart form selector
    and data setting in one operation. It selects the first form that contains all
    fields mentioned in `\%fields`.  This is nice because you don't need to know
    the name or number of the form to do this.

    (calls `["form_with_fields()"](#form_with_fields)` and `["set_fields()"](#set_fields)`).

    If you choose `with_fields`, the `fields` option will be ignored. The
    `form_number`, `form_name` and `form_id` options will still be used.  An
    exception will be thrown unless exactly one form matches all of the provided
    criteria.

- `form_number => n`

    Selects the _n_th form (calls
    `[form_number()](#mech-form_number-number)`.  If this parm is not
    specified, the currently-selected form is used.

- `form_name => name`

    Selects the form named _name_ (calls
    `[form_name()](#mech-form_name-name)`)

- `form_id => ID`

    Selects the form with ID _ID_ (calls
    `[form_id()](#mech-form_id-name)`)>>)

- `button => button`

    Clicks on button _button_ (calls `[click()](#mech-click-button-x-y)`)

- `x => x, y => y`

    Sets the x or y values for `[click()](#mech-click-button-x-y)`

- `strict_forms => bool`

    Sets the HTML::Form strict flag which causes form submission to croak if any of the passed
    fields don't exist on the page, and/or a value doesn't exist in a select element.
    By default HTML::Form sets this value to false.

    This behavior can also be turned on globally by passing `strict_forms => 1` to
    `WWW::Mechanize->new`. If you do that, you can still disable it for individual calls
    by passing `strict_forms => 0` here.

If no form is selected, the first form found is used.

If _button_ is not passed, then the [`submit()|"$mech->submit()"`](https://metacpan.org/pod/submit\(\)|&#x22;$mech->submit\(\)&#x22;)
method is used instead.

If you want to submit a file and get its content from a scalar rather
than a file in the filesystem, you can use:

    $mech->submit_form(with_fields => { logfile => [ [ undef, 'whatever', Content => $content ], 1 ] } );

Returns an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object.

# MISCELLANEOUS METHODS

## $mech->add\_header( name => $value \[, name => $value... \] )

Sets HTTP headers for the agent to add or remove from the HTTP request.

    $mech->add_header( Encoding => 'text/klingon' );

If a _value_ is `undef`, then that header will be removed from any
future requests.  For example, to never send a Referer header:

    $mech->add_header( Referer => undef );

If you want to delete a header, use `delete_header`.

Returns the number of name/value pairs added.

**NOTE**: This method was very different in WWW::Mechanize before 1.00.
Back then, the headers were stored in a package hash, not as a member of
the object instance.  Calling `add_header()` would modify the headers
for every WWW::Mechanize object, even after your object no longer existed.

## $mech->delete\_header( name \[, name ... \] )

Removes HTTP headers from the agent's list of special headers.  For
instance, you might need to do something like:

    # Don't send a Referer for this URL
    $mech->add_header( Referer => undef );

    # Get the URL
    $mech->get( $url );

    # Back to the default behavior
    $mech->delete_header( 'Referer' );

## $mech->quiet(true/false)

Allows you to suppress warnings to the screen.

    $mech->quiet(0); # turns on warnings (the default)
    $mech->quiet(1); # turns off warnings
    $mech->quiet();  # returns the current quietness status

## $mech->stack\_depth( $max\_depth )

Get or set the page stack depth. Use this if you're doing a lot of page
scraping and running out of memory.

A value of 0 means "no history at all."  By default, the max stack depth
is humongously large, effectively keeping all history.

## $mech->save\_content( $filename, %opts )

Dumps the contents of `$mech->content` into _$filename_.
_$filename_ will be overwritten.  Dies if there are any errors.

If the content type does not begin with "text/", then the content
is saved in binary mode (i.e. `binmode()` is set on the output
filehandle).

Additional arguments can be passed as _key_/_value_ pairs:

- _$mech->save\_content( $filename, binary => 1 )_

    Filehandle is set with `binmode` to `:raw` and contents are taken
    calling `$self->content(decoded_by_headers => 1)`. Same as calling:

        $mech->save_content( $filename, binmode => ':raw',
                             decoded_by_headers => 1 );

    This _should_ be the safest way to save contents verbatim.

- _$mech->save\_content( $filename, binmode => $binmode )_

    Filehandle is set to binary mode. If `$binmode` begins with ':', it is
    passed as a parameter to `binmode`:

        binmode $fh, $binmode;

    otherwise the filehandle is set to binary mode if `$binmode` is true:

        binmode $fh;

- _all other arguments_

    are passed as-is to `$mech->content(%opts)`. In particular,
    `decoded_by_headers` might come handy if you want to revert the effect
    of line compression performed by the web server but without further
    interpreting the contents (e.g. decoding it according to the charset).

## $mech->dump\_headers( \[$fh\] )

Prints a dump of the HTTP response headers for the most recent
response.  If _$fh_ is not specified or is undef, it dumps to
STDOUT.

Unlike the rest of the dump\_\* methods, $fh can be a scalar. It
will be used as a file name.

## $mech->dump\_links( \[\[$fh\], $absolute\] )

Prints a dump of the links on the current page to _$fh_.  If _$fh_
is not specified or is undef, it dumps to STDOUT.

If _$absolute_ is true, links displayed are absolute, not relative.

## $mech->dump\_images( \[\[$fh\], $absolute\] )

Prints a dump of the images on the current page to _$fh_.  If _$fh_
is not specified or is undef, it dumps to STDOUT.

If _$absolute_ is true, links displayed are absolute, not relative.

## $mech->dump\_forms( \[$fh\] )

Prints a dump of the forms on the current page to _$fh_.  If _$fh_
is not specified or is undef, it dumps to STDOUT. Running the following:

    my $mech = WWW::Mechanize->new();
    $mech->get("https://www.google.com/");
    $mech->dump_forms;

will print:

    GET https://www.google.com/search [f]
      ie=ISO-8859-1                  (hidden readonly)
      hl=en                          (hidden readonly)
      source=hp                      (hidden readonly)
      biw=                           (hidden readonly)
      bih=                           (hidden readonly)
      q=                             (text)
      btnG=Google Search             (submit)
      btnI=I'm Feeling Lucky         (submit)
      gbv=1                          (hidden readonly)

## $mech->dump\_text( \[$fh\] )

Prints a dump of the text on the current page to _$fh_.  If _$fh_
is not specified or is undef, it dumps to STDOUT.

# OVERRIDDEN LWP::UserAgent METHODS

## $mech->clone()

Clone the mech object.  The clone will be using the same cookie jar
as the original mech.

## $mech->redirect\_ok()

An overloaded version of `redirect_ok()` in [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent).
This method is used to determine whether a redirection in the request
should be followed.

Note that WWW::Mechanize's constructor pushes POST on to the agent's
`requests_redirectable` list.

## $mech->request( $request \[, $arg \[, $size\]\])

Overloaded version of `request()` in [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent).  Performs
the actual request.  Normally, if you're using WWW::Mechanize, it's
because you don't want to deal with this level of stuff anyway.

Note that `$request` will be modified.

Returns an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object.

## $mech->update\_html( $html )

Allows you to replace the HTML that the mech has found.  Updates the
forms and links parse-trees that the mech uses internally.

Say you have a page that you know has malformed output, and you want to
update it so the links come out correctly:

    my $html = $mech->content;
    $html =~ s[</option>.{0,3}</td>][</option></select></td>]isg;
    $mech->update_html( $html );

This method is also used internally by the mech itself to update its
own HTML content when loading a page. This means that if you would
like to _systematically_ perform the above HTML substitution, you
would overload _update\_html_ in a subclass thusly:

    package MyMech;
    use base 'WWW::Mechanize';

    sub update_html {
        my ($self, $html) = @_;
        $html =~ s[</option>.{0,3}</td>][</option></select></td>]isg;
        $self->WWW::Mechanize::update_html( $html );
    }

If you do this, then the mech will use the tidied-up HTML instead of
the original both when parsing for its own needs, and for returning to
you through ["content"](#content).

Overloading this method is also the recommended way of implementing
extra validation steps (e.g. link checkers) for every HTML page
received.  ["warn"](#warn) and ["die"](#die) would then come in handy to signal
validation errors.

## $mech->credentials( $username, $password )

Provide credentials to be used for HTTP Basic authentication for
all sites and realms until further notice.

The four argument form described in [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) is still
supported.

## $mech->get\_basic\_credentials( $realm, $uri, $isproxy )

Returns the credentials for the realm and URI.

## $mech->clear\_credentials()

Remove any credentials set up with `credentials()`.

# INHERITED UNCHANGED LWP::UserAgent METHODS

As a subclass of [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent), WWW::Mechanize inherits all of
[LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)'s methods.  Many of which are overridden or
extended. The following methods are inherited unchanged. View the
[LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) documentation for their implementation descriptions.

This is not meant to be an inclusive list.  LWP::UA may have added
others.

## $mech->head()

Inherited from [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent).

## $mech->mirror()

Inherited from [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent).

## $mech->simple\_request()

Inherited from [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent).

## $mech->is\_protocol\_supported()

Inherited from [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent).

## $mech->prepare\_request()

Inherited from [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent).

## $mech->progress()

Inherited from [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent).

# INTERNAL-ONLY METHODS

These methods are only used internally.  You probably don't need to
know about them.

## $mech->\_update\_page($request, $response)

Updates all internal variables in $mech as if $request was just
performed, and returns $response. The page stack is **not** altered by
this method, it is up to caller (e.g.
`[request](#mech-request-request-arg-size)`)
to do that.

## $mech->\_modify\_request( $req )

Modifies a [HTTP::Request](https://metacpan.org/pod/HTTP::Request) before the request is sent out,
for both GET and POST requests.

We add a `Referer` header, as well as header to note that we can accept gzip
encoded content, if [Compress::Zlib](https://metacpan.org/pod/Compress::Zlib) is installed.

## $mech->\_make\_request()

Convenience method to make it easier for subclasses like
[WWW::Mechanize::Cached](https://metacpan.org/pod/WWW::Mechanize::Cached) to intercept the request.

## $mech->\_reset\_page()

Resets the internal fields that track page parsed stuff.

## $mech->\_extract\_links()

Extracts links from the content of a webpage, and populates the `{links}`
property with [WWW::Mechanize::Link](https://metacpan.org/pod/WWW::Mechanize::Link) objects.

## $mech->\_push\_page\_stack()

The agent keeps a stack of visited pages, which it can pop when it needs
to go BACK and so on.

The current page needs to be pushed onto the stack before we get a new
page, and the stack needs to be popped when BACK occurs.

Neither of these take any arguments, they just operate on the $mech
object.

## warn( @messages )

Centralized warning method, for diagnostics and non-fatal problems.
Defaults to calling `CORE::warn`, but may be overridden by setting
`onwarn` in the constructor.

## die( @messages )

Centralized error method.  Defaults to calling `CORE::die`, but
may be overridden by setting `onerror` in the constructor.

# BEST PRACTICES

The default settings can get you up and running quickly, but there are settings
you can change in order to make your life easier.

- autocheck

    `autocheck` can save you the overhead of checking status codes for success.
    You may outgrow it as your needs get more sophisticated, but it's a safe option
    to start with.

        my $agent = WWW::Mechanize->new( autocheck => 1 );

- cookie\_jar

    You are encouraged to install [Mozilla::PublicSuffix](https://metacpan.org/pod/Mozilla::PublicSuffix) and use
    [HTTP::CookieJar::LWP](https://metacpan.org/pod/HTTP::CookieJar::LWP) as your cookie jar.  [HTTP::CookieJar::LWP](https://metacpan.org/pod/HTTP::CookieJar::LWP) provides a
    better security model matching that of current Web browsers when
    [Mozilla::PublicSuffix](https://metacpan.org/pod/Mozilla::PublicSuffix) is installed.

        use HTTP::CookieJar::LWP ();

        my $jar = HTTP::CookieJar::LWP->new;
        my $agent = WWW::Mechanize->new( cookie_jar => $jar );

- protocols\_allowed

    This option is inherited directly from [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent).  It allows you to
    whitelist the protocols you're willing to allow.

        my $agent = WWW::Mechanize->new(
            protocols_allowed => [ 'http', 'https' ]
        );

    This will prevent you from inadvertently following URLs like
    `file:///etc/passwd`

- protocols\_forbidden

    This option is also inherited directly from [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent).  It allows you to
    blacklist the protocols you're unwilling to allow.

        my $agent = WWW::Mechanize->new(
            protocols_forbidden => [ 'file', 'mailto', 'ssh', ]
        );

    This will prevent you from inadvertently following URLs like
    `file:///etc/passwd`

- strict\_forms

    Consider turning on the `strict_forms` option when you create a new Mech.
    This will perform a helpful sanity check on form fields every time you are
    submitting a form, which can save you a lot of debugging time.

        my $agent = WWW::Mechanize->new( strict_forms => 1 );

    If you do not want to have this option globally, you can still turn it on for
    individual forms.

        $agent->submit_form( fields => { foo => 'bar' } , strict_forms => 1 );

# WWW::MECHANIZE'S GIT REPOSITORY

WWW::Mechanize is hosted at GitHub.

Repository: [https://github.com/libwww-perl/WWW-Mechanize](https://github.com/libwww-perl/WWW-Mechanize).
Bugs: [https://github.com/libwww-perl/WWW-Mechanize/issues](https://github.com/libwww-perl/WWW-Mechanize/issues).

# OTHER DOCUMENTATION

## _Spidering Hacks_, by Kevin Hemenway and Tara Calishain

_Spidering Hacks_ from O'Reilly
([http://www.oreilly.com/catalog/spiderhks/](http://www.oreilly.com/catalog/spiderhks/)) is a great book for anyone
wanting to know more about screen-scraping and spidering.

There are six hacks that use Mech or a Mech derivative:

- #21 WWW::Mechanize 101
- #22 Scraping with WWW::Mechanize
- #36 Downloading Images from Webshots
- #44 Archiving Yahoo! Groups Messages with WWW::Yahoo::Groups
- #64 Super Author Searching
- #73 Scraping TV Listings

The book was also positively reviewed on Slashdot:
[http://books.slashdot.org/article.pl?sid=03/12/11/2126256](http://books.slashdot.org/article.pl?sid=03/12/11/2126256)

# ONLINE RESOURCES AND SUPPORT

- WWW::Mechanize mailing list

    The Mech mailing list is at
    [http://groups.google.com/group/www-mechanize-users](http://groups.google.com/group/www-mechanize-users) and is specific
    to Mechanize, unlike the LWP mailing list below.  Although it is a
    users list, all development discussion takes place here, too.

- LWP mailing list

    The LWP mailing list is at
    [http://lists.perl.org/showlist.cgi?name=libwww](http://lists.perl.org/showlist.cgi?name=libwww), and is more
    user-oriented and well-populated than the WWW::Mechanize list.

- Perlmonks

    [http://perlmonks.org](http://perlmonks.org) is an excellent community of support, and
    many questions about Mech have already been answered there.

- [WWW::Mechanize::Examples](https://metacpan.org/pod/WWW::Mechanize::Examples)

    A random array of examples submitted by users, included with the
    Mechanize distribution.

# ARTICLES ABOUT WWW::MECHANIZE

- [http://www.ibm.com/developerworks/linux/library/wa-perlsecure/](http://www.ibm.com/developerworks/linux/library/wa-perlsecure/)

    IBM article "Secure Web site access with Perl"

- [http://www.oreilly.com/catalog/googlehks2/chapter/hack84.pdf](http://www.oreilly.com/catalog/googlehks2/chapter/hack84.pdf)

    Leland Johnson's hack #84 in _Google Hacks, 2nd Edition_ is
    an example of a production script that uses WWW::Mechanize and
    HTML::TableContentParser. It takes in keywords and returns the estimated
    price of these keywords on Google's AdWords program.

- [http://www.perl.com/pub/a/2004/06/04/recorder.html](http://www.perl.com/pub/a/2004/06/04/recorder.html)

    Linda Julien writes about using HTTP::Recorder to create WWW::Mechanize
    scripts.

- [http://www.developer.com/lang/other/article.php/3454041](http://www.developer.com/lang/other/article.php/3454041)

    Jason Gilmore's article on using WWW::Mechanize for scraping sales
    information from Amazon and eBay.

- [http://www.perl.com/pub/a/2003/01/22/mechanize.html](http://www.perl.com/pub/a/2003/01/22/mechanize.html)

    Chris Ball's article about using WWW::Mechanize for scraping TV
    listings.

- [http://www.stonehenge.com/merlyn/LinuxMag/col47.html](http://www.stonehenge.com/merlyn/LinuxMag/col47.html)

    Randal Schwartz's article on scraping Yahoo News for images.  It's
    already out of date: He manually walks the list of links hunting
    for matches, which wouldn't have been necessary if the
    `[find_link()](#mech-find_link)` method existed at press time.

- [http://www.perladvent.org/2002/16th/](http://www.perladvent.org/2002/16th/)

    WWW::Mechanize on the Perl Advent Calendar, by Mark Fowler.

- [http://www.linux-magazin.de/ausgaben/2004/03/datenruessel/](http://www.linux-magazin.de/ausgaben/2004/03/datenruessel/)

    Michael Schilli's article on Mech and [WWW::Mechanize::Shell](https://metacpan.org/pod/WWW::Mechanize::Shell) for the
    German magazine _Linux Magazin_.

## Other modules that use Mechanize

Here are modules that use or subclass Mechanize.  Let me know of any others:

- [Finance::Bank::LloydsTSB](https://metacpan.org/pod/Finance::Bank::LloydsTSB)
- [HTTP::Recorder](https://metacpan.org/pod/HTTP::Recorder)

    Acts as a proxy for web interaction, and then generates WWW::Mechanize scripts.

- [Win32::IE::Mechanize](https://metacpan.org/pod/Win32::IE::Mechanize)

    Just like Mech, but using Microsoft Internet Explorer to do the work.

- [WWW::Bugzilla](https://metacpan.org/pod/WWW::Bugzilla)
- [WWW::CheckSite](https://metacpan.org/pod/WWW::CheckSite)
- [WWW::Google::Groups](https://metacpan.org/pod/WWW::Google::Groups)
- [WWW::Hotmail](https://metacpan.org/pod/WWW::Hotmail)
- [WWW::Mechanize::Cached](https://metacpan.org/pod/WWW::Mechanize::Cached)
- [WWW::Mechanize::Cached::GZip](https://metacpan.org/pod/WWW::Mechanize::Cached::GZip)
- [WWW::Mechanize::FormFiller](https://metacpan.org/pod/WWW::Mechanize::FormFiller)
- [WWW::Mechanize::Shell](https://metacpan.org/pod/WWW::Mechanize::Shell)
- [WWW::Mechanize::Sleepy](https://metacpan.org/pod/WWW::Mechanize::Sleepy)
- [WWW::Mechanize::SpamCop](https://metacpan.org/pod/WWW::Mechanize::SpamCop)
- [WWW::Mechanize::Timed](https://metacpan.org/pod/WWW::Mechanize::Timed)
- [WWW::SourceForge](https://metacpan.org/pod/WWW::SourceForge)
- [WWW::Yahoo::Groups](https://metacpan.org/pod/WWW::Yahoo::Groups)
- [WWW::Scripter](https://metacpan.org/pod/WWW::Scripter)

# ACKNOWLEDGEMENTS

Thanks to the numerous people who have helped out on WWW::Mechanize in
one way or another, including
Kirrily Robert for the original `WWW::Automate`,
Lyle Hopkins,
Damien Clark,
Ansgar Burchardt,
Gisle Aas,
Jeremy Ary,
Hilary Holz,
Rafael Kitover,
Norbert Buchmuller,
Dave Page,
David Sainty,
H.Merijn Brand,
Matt Lawrence,
Michael Schwern,
Adriano Ferreira,
Miyagawa,
Peteris Krumins,
Rafael Kitover,
David Steinbrunner,
Kevin Falcone,
Mike O'Regan,
Mark Stosberg,
Uri Guttman,
Peter Scott,
Philippe Bruhat,
Ian Langworth,
John Beppu,
Gavin Estey,
Jim Brandt,
Ask Bjoern Hansen,
Greg Davies,
Ed Silva,
Mark-Jason Dominus,
Autrijus Tang,
Mark Fowler,
Stuart Children,
Max Maischein,
Meng Wong,
Prakash Kailasa,
Abigail,
Jan Pazdziora,
Dominique Quatravaux,
Scott Lanning,
Rob Casey,
Leland Johnson,
Joshua Gatcomb,
Julien Beasley,
Abe Timmerman,
Peter Stevens,
Pete Krawczyk,
Tad McClellan,
and the late great Iain Truskett.

# AUTHOR

Andy Lester &lt;andy at petdance.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2004-2016 by Andy Lester.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
