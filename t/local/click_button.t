use warnings;
use strict;

use lib 't/local';

use LocalServer ();
use Test::More 0.96;
use Test::Fatal qw(dies_ok);

BEGIN {
    delete @ENV{qw( IFS CDPATH ENV BASH_ENV )};
    use_ok('WWW::Mechanize');
}

my $mech = WWW::Mechanize->new();
isa_ok( $mech, 'WWW::Mechanize', 'Created the object' );

my $server = LocalServer->spawn();
isa_ok( $server, 'LocalServer' );

dies_ok { $mech->click_button( id => 0 ) } 'Dies without a form';

my $response = $mech->get( $server->url );
isa_ok( $response, 'HTTP::Response', 'Got back a response' );
ok( $response->is_success, 'Got URL' ) or die q{Can't even fetch local url};
ok( $mech->is_html,        'Local page is HTML' );

my @forms = $mech->forms;
my $form  = $forms[0];

subtest 'click by id' => sub {
    $mech->click_button( id => 0 );
    test_click($mech);

    ok(
        !eval { $mech->click_button( id => 'i-do-not-exist' ); 1 },
        'Button id not found'
    );
};

subtest 'click by number' => sub {
    $mech->click_button( number => 1 );
    test_click($mech);

    ok(
        !eval { $mech->click_button( number => 3 ); 1 },
        'Button number out of range'
    );
};

subtest 'click by name' => sub {
    $mech->click_button( name => 'submit' );
    test_click($mech);

    ok(
        !eval { $mech->click_button( name => 'bogus' ); 1 },
        'Button name unknown'
    );
};

subtest 'click a <button> tag' => sub {
    $mech->click_button( name => 'button_tag' );
    test_click( $mech, 'button_tag', 'Walk' );
};

subtest 'click by value' => sub {

    # input tag
    $mech->click_button( value => 'Go' );
    test_click($mech);

    # button tag
    $mech->click_button( value => 'Walk' );
    test_click( $mech, 'button_tag', 'Walk' );

    # image type
    $mech->click_button( value => 'image' );
    {
        like( $mech->uri, qr/formsubmit/, 'Clicking on button' );
        like(
            $mech->uri, qr/image_input\.x=1/,
            'Correct button was pressed'
        );
        like( $mech->uri, qr/cat_foo/, 'Parameters got transmitted OK' );
        unlike( $mech->uri, qr/Go/, 'Submit button was not transmitted' );
    }

    ok(
        !eval { $mech->click_button( value => 'bogus' ); 1 },
        'Button name unknown'
    );
};

CLICK_BY_OBJECT_REFERENCE: {
    subtest 'click by object reference' => sub {
        my $clicky_button = $form->find_input( undef, 'submit' );
        isa_ok(
            $clicky_button, 'HTML::Form::Input',
            'Found the submit button'
        );
        is( $clicky_button->value, 'Go', 'Named the right thing, too' );

        my $res = $mech->click_button( input => $clicky_button );
        local $TODO
            = q{Calling ->click() on an object doesn't seem to use the submit button.};
        test_click($mech);
        diag $res->request->uri;
    };
}

subtest 'multiple button selectors' => sub {
    dies_ok { $mech->click_button( id => 0, input => 1 ) }
    'Dies when multiple button selectors are used';
};

subtest 'click with coordinates' => sub {
    $mech->click_button( name => 'button_tag', x => 10, y => 5 );
    test_click( $mech, 'button_tag', 'Walk' );
};

sub test_click {
    my $mech  = shift;
    my $name  = shift || 'submit';
    my $value = shift || 'Go';
    like( $mech->uri, qr/formsubmit/,   'Clicking on button' );
    like( $mech->uri, qr/$name=$value/, 'Correct button was pressed' );
    like( $mech->uri, qr/cat_foo/,      'Parameters got transmitted OK' );
    $mech->back;
}

done_testing();
