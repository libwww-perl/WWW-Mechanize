#!perl -T

use warnings;
use strict;

use Test::More;
use URI::file ();

BEGIN {
    use_ok('WWW::Mechanize');
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $uri = URI::file->new_abs('t/find_link_xhtml.html')->as_string;

$mech->get($uri);
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

my @links    = map { [ $_->text, $_->url ] } $mech->links();
my @expected = (
    [ 'One',   'http://www.example.com/1' ],
    [ 'Five',  'http://www.example.com/5' ],
    [ 'Seven', 'http://www.example.com/7' ],
);

is_deeply \@links, \@expected, "We find exactly the valid links";

# now, test with explicit marked_sections => 1

$mech = WWW::Mechanize->new( cookie_jar => undef, marked_sections => 1 );
isa_ok( $mech, 'WWW::Mechanize' );

$uri = URI::file->new_abs('t/find_link_xhtml.html')->as_string;

$mech->get($uri);
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

@links    = map { [ $_->text, $_->url ] } $mech->links();
@expected = (
    [ 'One',   'http://www.example.com/1' ],
    [ 'Five',  'http://www.example.com/5' ],
    [ 'Seven', 'http://www.example.com/7' ],
);

is_deeply \@links, \@expected, "We find exactly the valid links, explicitly";

# now, test with marked_sections => 0, giving us legacy results

$mech = WWW::Mechanize->new( cookie_jar => undef, marked_sections => undef );
isa_ok( $mech, 'WWW::Mechanize' );

$uri = URI::file->new_abs('t/find_link_xhtml.html')->as_string;

$mech->get($uri);
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

@links    = map { [ $_->text, $_->url ] } $mech->links();
@expected = (
    [ 'One',  'http://www.example.com/1' ],
    [ 'Five', 'http://www.example.com/5' ],
    [ 'Six',  'http://www.example.com/6' ],    # yeah...
);

is_deeply \@links, \@expected, "We can enable the legacy behaviour";

done_testing();
