#!perl -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class) = shift;
    return bless {}, $class;
}

sub PRINT  {
    my($self) = shift;
    $main::_STDOUT_ .= join '', @_;
}

sub READ {}
sub READLINE {}
sub GETC {}

package main;

local $SIG{__WARN__} = sub { $_STDERR_ .= join '', @_ };
tie *STDOUT, 'Catch' or die $!;


{
#line 72 lib/WWW/Automate.pm

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


}

{
#line 121 lib/WWW/Automate.pm

ok($agent->get("http://google.com"), "Get google webpage");
isa_ok($agent->{uri}, "URI", "Set uri");
isa_ok($agent->{req}, 'HTTP::Request', "req should be a HTTP::Request");


}

{
#line 144 lib/WWW/Automate.pm

ok(! $agent->follow(99999), "Can't follow too-high-numbered link");
ok($agent->follow(1), "Can follow first link");
ok($agent->back(), "Can go back");

ok(! $agent->follow(qr/asdfghjksdfghj/), "Can't follow unlikely named link");
ok($agent->follow("Search"), "Can follow obvious named link");
$agent->back();


}

{
#line 202 lib/WWW/Automate.pm

my $t = WWW::Automate->new();
$t->get("http://google.com");
ok($t->form(1), "Can select the first form");
is($t->{form}, $t->{forms}->[0], "Set the form attribute");
ok(! $t->form(99), "Can't select the 99th form");
is($t->{form}, $t->{forms}->[0], "Form is still set to 1");


}

{
#line 253 lib/WWW/Automate.pm

my $t = WWW::Automate->new();
$t->get("http://google.com");
$t->field(q => "foo");
ok($t->click("btnG"), "Can click 'btnG' ('Google Search' button)");
like($t->{content}, qr/foo\s?fighters/i, "Found 'Foo Fighters'");


}

{
#line 307 lib/WWW/Automate.pm

$agent->add_header(foo => 'bar');
is($WWW::Automate::headers{'foo'}, 'bar', "set header");


}

{
#line 339 lib/WWW/Automate.pm

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



}

