#!/usr/local/bin/perl -w

use Test::More tests=>1;
use HTML::Form;

diag( "Version dump" );
for my $file ( sort keys %INC ) {
    my $module = $file;
    $module =~ s[/][::]g;
    $module =~ s/\.pm$//;
    diag( ($module->VERSION||"undef") . "\t" . $module );
}

my $base = "http://localhost/";
my $content = do { local $/ = undef; <DATA> };

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

