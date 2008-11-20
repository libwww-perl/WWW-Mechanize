#!perl

use warnings;
use strict;
use lib 't/local';
use LocalServer;
use Test::More tests => 19;

BEGIN {
    delete @ENV{ grep { lc eq 'http_proxy' } keys %ENV };
    delete @ENV{ qw( IFS CDPATH ENV BASH_ENV ) };
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new();
isa_ok( $mech, 'WWW::Mechanize', 'Created the object' );

my $server = LocalServer->spawn();
isa_ok( $server, 'LocalServer' );

my $response = $mech->get( $server->url );
isa_ok( $response, 'HTTP::Response', 'Got back a response' );
ok( $response->is_success, 'Got URL' ) or die q{Can't even fetch local url};
ok( $mech->is_html, 'Local page is HTML' );

my @forms = $mech->forms;
my $form = $forms[0];

CLICK_BY_NUMBER: {
    $mech->click_button(number => 1);

    like( $mech->uri, qr/formsubmit/, 'Clicking on button by number' );
    like( $mech->uri, qr/submit=Go/,  'Correct button was pressed' );
    like( $mech->uri, qr/cat_foo/,    'Parameters got transmitted OK' );
    $mech->back;

    ok(! eval { $mech->click_button(number => 2); 1 }, 'Button number out of range');
}

CLICK_BY_NAME: {
    $mech->click_button(name => 'submit');
    like( $mech->uri, qr/formsubmit/, 'Clicking on button by name' );
    like( $mech->uri, qr/submit=Go/,  'Correct button was pressed' );
    like( $mech->uri, qr/cat_foo/,    'Parameters got transmitted OK' );
    $mech->back;

    ok(! eval { $mech->click_button(name => 'bogus'); 1 },
    'Button name unknown');
}

CLICK_BY_OBJECT_REFERENCE: {
    local $TODO = q{It seems that calling ->click() on an object is broken in LWP. Need to investigate further.};

    my $clicky_button = $form->find_input( undef, 'submit' );
    isa_ok( $clicky_button, 'HTML::Form::Input', 'Found the submit button' );
    is( $clicky_button->value, 'Go', 'Named the right thing, too' );

    my $resp = $mech->click_button(input => $clicky_button);
    {use Data::Dumper; local $Data::Dumper::Sortkeys=1;
        diag Dumper( $resp->request )}

    like( $mech->uri, qr/formsubmit/, 'Clicking on button by object reference' );
    like( $mech->uri, qr/submit=Go/,  'Correct button was pressed' );
    like( $mech->uri, qr/cat_foo/,    'Parameters got transmitted OK' );

    $mech->back;
}
