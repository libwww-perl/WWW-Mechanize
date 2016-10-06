#!perl -Tw

use warnings;
use strict;
use Test::More 'no_plan';
use URI::file ();

BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};  # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef, autocheck => 0 );
isa_ok( $mech, 'WWW::Mechanize' );
my $uri = URI::file->new_abs( 't/form_with_fields.html' )->as_string;

$mech->get( $uri );
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

{
    my $test = 'dies with no input';
    eval{  my $form = $mech->form_with_fields(); };
    ok($@,$test);
}

{
    my $form = $mech->form_with_fields(qw/1b/);
    isa_ok( $form, 'HTML::Form' );
    is($form->attr('name'), '1st_form', 'first form matches');
}

{
    my $form = $mech->form_with_fields('1b', 'opt[2]');
    isa_ok( $form, 'HTML::Form' );
    is($form->attr('name'), '2nd_form', 'second form matches');
}

{
    $mech->get($uri);
    eval { $mech->submit_form(
            with_fields => { '1b' => '', 'opt[2]' => '' },
        ); };
    is($@,'', ' submit_form( with_fields => %data ) ' );
}

{
    $mech->get($uri);
    eval {
        $mech->submit_form(
            form_name => '1st_form',
            fields => {
                '1c' => 'madeup_field',
            },
        );
    };
    is($@, '', 'submit_form with invalid field and without strict option succeeds');
}

{
    $mech->get($uri);
    eval {
        $mech->submit_form(
            form_name => '1st_form',
            fields => {
                '1c' => 'madeup_field',
            },
            strict => 1,
        );
    };
    like($@, qr/^No such field \'1c\'/, 'submit_form with invalid field and strict option fails');
}

{
    $mech->get($uri);
    eval {
        $mech->submit_form(
            form_name => '1st_form',
            fields => {
                '1a' => 'value1',
                '1b' => 'value2',
            },
            strict => 1,
        );
    };
    is($@, '', 'submit_form with valid fields and strict option succeeds');
}
