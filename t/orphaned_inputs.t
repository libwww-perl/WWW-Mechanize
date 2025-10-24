#!perl

use warnings;
use strict;

use Test::More tests => 14;
use URI::file ();

BEGIN {
    use_ok('WWW::Mechanize');
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

# Test case 1: Nested forms (form2 inside form1)
# HTML::Form stops at the first </form> tag, which belongs to form2,
# leaving inputs after form2 as "orphaned"
{
    my $html = <<'HTML';
<html>
<body>
<form action="/search1" method="post" name="form1">
    <input type="text" name="query" value="" />
    <input type="submit" name="search" value="Search" />
    
    <!-- Nested form - causes HTML::Form to stop prematurely -->
    <form action="/search2" method="post" name="form2">
        <input type="hidden" name="inner" value="1" />
    </form>
    
    <!-- These inputs are orphaned after the first </form> tag -->
    <input type="hidden" name="page" value="1" />
    <input type="submit" name="next" value="Next" />
</form>
</body>
</html>
HTML

    my $uri = URI::file->new_abs('t/orphaned_inputs.html')->as_string;
    
    # Write the HTML to a temp file
    open my $fh, '>', 't/orphaned_inputs.html' or die "Cannot write test file: $!";
    print $fh $html;
    close $fh;
    
    $mech->get($uri);
    ok( $mech->success, "Fetched test page" );
    
    # HTML::Form only recognizes one form (form1)
    my @forms = $mech->forms;
    is( scalar @forms, 1, 'Exactly one form recognized' );
    
    # But all inputs should be found, including orphaned ones
    my @inputs = $mech->find_all_inputs();
    is( scalar @inputs, 5, 'All 5 inputs found including orphaned ones' );
    
    # Check that specific orphaned inputs are found
    my @page_inputs = $mech->find_all_inputs( name => 'page' );
    is( scalar @page_inputs, 1, 'Found orphaned "page" input' );
    
    my @next_buttons = $mech->find_all_submits( name => 'next' );
    is( scalar @next_buttons, 1, 'Found orphaned "next" submit button' );
    
    # All submits should be found
    my @submits = $mech->find_all_submits();
    is( scalar @submits, 2, 'Found both submit buttons' );
    
    # Clean up
    unlink 't/orphaned_inputs.html';
}

# Test case 2: Premature </form> tag
# Explicit premature closing tag in HTML source
{
    my $html = <<'HTML';
<html>
<body>
<form action="/search" method="post" name="search_form">
    <input type="text" name="query" value="" />
    <input type="submit" name="search" value="Search" />
    <table><tr><td>content</td></tr></table>
    </form>
    <!-- Premature close - inputs after this are orphaned -->
    <input type="hidden" name="page" value="1" />
    <input type="submit" name="next" value="Next" />
</body>
</html>
HTML

    # Write the HTML to a temp file
    open my $fh, '>', 't/orphaned_inputs2.html' or die "Cannot write test file: $!";
    print $fh $html;
    close $fh;
    
    my $uri = URI::file->new_abs('t/orphaned_inputs2.html')->as_string;
    $mech->get($uri);
    ok( $mech->success, "Fetched second test page" );
    
    my @inputs = $mech->find_all_inputs();
    is( scalar @inputs, 4, 'All 4 inputs found with premature </form>' );
    
    my @next_buttons = $mech->find_all_submits( name => 'next' );
    is( scalar @next_buttons, 1, 'Found orphaned "next" button after premature </form>' );
    
    my @submits = $mech->find_all_submits();
    is( scalar @submits, 2, 'Found both submits with premature </form>' );
    
    # Clean up
    unlink 't/orphaned_inputs2.html';
}

# Test case 3: Normal form (sanity check)
# Make sure we don't break normal forms without orphaned inputs
{
    my $html = <<'HTML';
<html>
<body>
<form action="/search" method="post" name="normal_form">
    <input type="text" name="query" value="" />
    <input type="submit" name="search" value="Search" />
</form>
</body>
</html>
HTML

    # Write the HTML to a temp file
    open my $fh, '>', 't/orphaned_inputs3.html' or die "Cannot write test file: $!";
    print $fh $html;
    close $fh;
    
    my $uri = URI::file->new_abs('t/orphaned_inputs3.html')->as_string;
    $mech->get($uri);
    ok( $mech->success, "Fetched normal form test page" );
    
    my @inputs = $mech->find_all_inputs();
    is( scalar @inputs, 2, 'Normal form: found 2 inputs' );
    
    # Clean up
    unlink 't/orphaned_inputs3.html';
}
