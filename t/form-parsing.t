#!/usr/local/bin/perl -w

use Test::More tests=>1;
use HTML::Form;
use HTML::Parser;
use HTML::TokeParser;

for my $module ( qw( HTML::Form HTML::Parser HTML::TokeParser ) ) {
    diag( "$module is " . $module->VERSION );
}

my $base = "http://localhost/";
my $content = join "", <DATA>;

my $forms = [ HTML::Form->parse( $content, $base ) ];
is( scalar @$forms, 1, "Find one form, please" );

__DATA__
<html>
<head>
<title>WWW::Mechanize::Shell test page</title>
</head>
<body>
  <form name="f" action="/formsubmit">
    <input type="checkbox" name="cat" value="cat_baz"  />
  </form>
</body>
</html>

