#!/usr/bin/perl -w 
# 
# WWW::Automate (c) 2002 Kirrily Robert <skud@cpan.org>
# This software is distributed under the same licenses as Perl; see
# the file COPYING for details.

#
# $Id: Automate.pm,v 1.6 2002/02/13 12:46:40 skud Exp $
#

package WWW::Automate;

use HTTP::Request;
use LWP::UserAgent;
use HTML::Form;
use HTML::TokeParser;
use Clone qw(clone);
use Carp;

our @ISA = qw( LWP::UserAgent );

my $VERSION = $VERSION = "0.10";

=pod 

=head1 NAME

WWW::Automate - automate interaction with websites

=head1 SYNOPSIS

  use WWW::Automate;
  my $agent = WWW::Automate->new();

  $agent->get($url);
  $agent->follow($link);
  $agent->form($number);
  $agent->field($name, $value);
  $agent->click($button);
  print "OK" if $agent->{content} =~ /$expected/;

=head1 DESCRIPTION

This module is intended to help you automate interaction with a website.
It bears a not-very-remarkable outwards resemblance to WWW::Chat, on
which it is based.  The main difference between this module and
WWW::Chat is that WWW::Chat requires a pre-processing stage before you
can run your script, whereas WWW::Automate does not.

WWW::Automate is a subclass of LWP::UserAgent, so anything you can do
with an LWP::UserAgent, you can also do with this.  See
L<LWP::UserAgent> for more information on the possibilities.

=head2 new()

Creates and returns a new WWW::Automate object, hereafter referred to as
the 'agent'.

    my $agent = WWW::Automate->new()

=begin testing

BEGIN: {
    use lib qw(lib/);
    use_ok('WWW::Automate');
    use vars qw($agent);
}

ok(WWW::Automate->can('new'), "can we call new?");
ok($agent = WWW::Automate->new(), "create agent object");
isa_ok($agent, 'WWW::Automate', "agent is a WWW::Automate");
can_ok($agent, 'request');  # as a subclass of LWP::UserAgent
like($agent->agent(), qr/WWW-Automate/, "Set user agent string");
like($agent->agent(), qr/$WWW::Automate::VERSION/, "Set user agent version");

=end testing

=cut

our $base = "http://localhost/";

sub new {
    shift;
    my $self = { page_stack => [] };
    bless $self;
    $self->agent("WWW-Automate-$VERSION");
    $self->env_proxy();
    return $self;
}

=head2 $agent->get($url)

Given a URL/URI, fetches it.  

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

You can get at them with, for example: $agent->{content}

=begin testing

ok($agent->get("http://google.com"), "Get google webpage");
isa_ok($agent->{uri}, "URI", "Set uri");
isa_ok($agent->{req}, 'HTTP::Request', "req should be a HTTP::Request");

=end testing

=cut

sub get {
    my ($self, $uri) = @_;
    $self->{uri} = URI->new_abs($uri, $base);
    $self->{req} = HTTP::Request->new(GET => $uri);
    $self->do_request(); 
}

=head2 $agent->follow($string|$num)

Follow a link.  If you provide a string, the first link whose text 
matches that string will be followed.  If you provide a number, it will 
be the nth link on the page.

=begin testing

ok(! $agent->follow(99999), "Can't follow too-high-numbered link");
ok($agent->follow(1), "Can follow first link");
ok($agent->back(), "Can go back");

ok(! $agent->follow(qr/asdfghjksdfghj/), "Can't follow unlikely named link");
ok($agent->follow("Search"), "Can follow obvious named link");
$agent->back();

=end testing

=cut

sub follow {
    my ($self, $link) = @_;
    my @links = @{$self->{links}};
    my $thislink;
    if (isnumber($link)) {
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

    $self->push_page_stack();
    #print STDERR "thislink is $thislink, base is $self->{base}";
    $self->{uri} = URI->new_abs($thislink, $self->{base});
    $self->{req} = HTTP::Request->new(GET => $self->{uri});
    $self->do_request();

    return 1;
}

=head2 $agent->form($number)

Selects the Nth form on the page as the target for subsequent calls to
field() and click().  Emits a warning and returns false if there is no
such form.  Forms are indexed from 1, that is to say, the first form is
number 1 (not zero).

=begin testing

my $t = WWW::Automate->new();
$t->get("http://google.com");
ok($t->form(1), "Can select the first form");
is($t->{form}, $t->{forms}->[0], "Set the form attribute");
ok(! $t->form(99), "Can't select the 99th form");
is($t->{form}, $t->{forms}->[0], "Form is still set to 1");

=end testing

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
    if ($number > 1) {
        $form->find_input($name, $number)->value($value);
    } else {
        $self->{form}->value($name => $value);
    }
}

=head2 $agent->click($button, $x, $y);

Has the effect of clicking a button on a form.  This method takes an
optional method which is the name of the button to be pressed.  If there
is only one button on the form, it simply clicks that one button.

=begin testing

my $t = WWW::Automate->new();
$t->get("http://google.com");
$t->field(q => "foo");
ok($t->click("btnG"), "Can click 'btnG' ('Google Search' button)");
like($t->{content}, qr/foo\s?fighters/i, "Found 'Foo Fighters'");

=end testing

=cut

sub click {
    my ($self, $button, $x, $y) = @_;
    for ($x, $y) { $_ = 1 unless defined; }
    $self->push_page_stack();
    $self->{uri} = $self->{form}->uri;
    $self->{req} = $self->{form}->click($name, $x, $y);
    $self->do_request();
}

=head2 $agent->submit()

Shortcut for $a->click("submit")

=cut

sub submit {
    my ($self) = shift;
    $self->click("submit");
}

=head2 $agent->back();

The equivalent of hitting the "back" button in a browser.  Returns to
the previous page.  Won't go back past the first page.

=cut

sub back {
    my $self = shift;
    $self->pop_page_stack;
}

=head1 INTERNAL METHODS

These methods are only used internally.  You probably don't need to 
know about them.

=head2 push_page_stack()

=head2 pop_page_stack()

The agent keeps a stack of visited pages, which it can pop when it needs
to go BACK and so on.  

The current page needs to be pushed onto the stack before we get a new
page, and the stack needs to be popped when BACK occurs.

Neither of these take any arguments, they just operate on the $agent
object.

=begin testing

my $t = WWW::Automate->new();
$t->get("http://www.google.com");
is(scalar @{$t->{page_stack}}, 0, "Page stack starts empty");
$t->push_page_stack();
is(scalar @{$t->{page_stack}}, 1, "Pushed item onto page stack");
$t->push_page_stack();
is(scalar @{$t->{page_stack}}, 2, "Pushed item onto page stack");
$t->pop_page_stack();
is(scalar @{$t->{page_stack}}, 1, "Popped item from page stack");
$t->pop_page_stack();
is(scalar @{$t->{page_stack}}, 0, "Popped item from page stack");
$t->pop_page_stack();
is(scalar @{$t->{page_stack}}, 0, "Can't pop beyond end of page stack");


=end testing

=cut

sub push_page_stack {
    my $self = shift;
    $self->{page_stack} = [ @{$self->{page_stack}}, clone($self)];
    return 1;
}

sub pop_page_stack {
    my $self = shift;
    if (@{$self->{page_stack}}) {
        $self = pop @{$self->{page_stack}};
        bless $self;
    }
    return 1;
}

=head2 extract_links()

Extracts HREF links from the content of a webpage.

=cut

sub extract_links {
    my $self = shift;
    my $p = HTML::TokeParser->new(\$self->{content});
    my @links;

    while (my $token = $p->get_tag("a")) {
        my $url = $token->[1]{href};
        next unless defined $url;   # probably just a name link
        my $text = $p->get_trimmed_text("/a");
        push(@links, [$url => $text]);
    }
    return \@links;
}

=head2 do_request()

Actually performs a request on the $self->{req} request object, and sets
a bunch of attributes on $self.

=cut

sub do_request {
    my ($self) = @_;
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
}

sub isnumber {
    my $in = shift;
    if ($in =~ /^\d+$/) {
        return 1;
    } else {
        return 0;
    }
}

=head1 BUGS

Please report any bugs via the system at http://rt.cpan.org/

=head1 AUTHOR

Kirrily "Skud" Robert <skud@cpan.org>

=cut

1;
