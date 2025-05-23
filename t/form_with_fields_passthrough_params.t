#!perl

use warnings;
use strict;
use Test::More 'no_plan';
use Test::Fatal qw( exception );
use Test::Warnings ':all';
use Test::Deep qw( cmp_deeply re );
use URI::file  ();

BEGIN {
    use_ok('WWW::Mechanize');
}

my $mech = WWW::Mechanize->new(
    cookie_jar   => undef, autocheck     => 0,
    strict_forms => 1,     verbose_forms => 1
);
isa_ok( $mech, 'WWW::Mechanize' );
my $uri = URI::file->new_abs('t/form_with_fields.html')->as_string;

$mech->get($uri);
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

{
    my $test = 'dies with no input';
    like(
        exception { my $form = $mech->form_with_fields(); },
        qr/no fields provided/,
        $test,
    );
}

{
    my $form;
    cmp_deeply(
        [ warnings { $form = $mech->form_with_fields(qw/1b/) } ],
        [
            re(
                qr/There are 2 forms with the named fields.  The first one was used./
            )
        ],
        'warning on ambiguous match (1)',
    );
    isa_ok( $form, 'HTML::Form' );
    is( $form->attr('name'), '1st_form', 'first form matches' );
}

{
    my $form = $mech->form_with_fields( '1b', 'opt[2]' );
    isa_ok( $form, 'HTML::Form' );
    is( $form->attr('name'), '2nd_form', 'second form matches' );
}

{
    my $form;
    cmp_deeply(
        [ warnings { $form = $mech->form_with_fields( '4a', '4b' ) } ],
        [
            re(
                qr/There are 2 forms with the named fields.  The first one was used./
            )
        ],
        'warning on ambiguous match (2)',
    );
    isa_ok( $form, 'HTML::Form' );
    is( $form->attr('name'), '4th_form_1', 'fourth form matches' );
}

{
    my @forms = $mech->all_forms_with( name => '3rd_form_ambiguous' );
    is( scalar @forms, 2 );
    isa_ok( $forms[0], 'HTML::Form' );
    isa_ok( $forms[1], 'HTML::Form' );
    is(
        $forms[0]->attr('name'), '3rd_form_ambiguous',
        'first result of 3rd_form_ambiguous'
    );
    is(
        $forms[1]->attr('name'), '3rd_form_ambiguous',
        'second result of 3rd_form_ambiguous'
    );
}

{
    $mech->get($uri);
    like(
        exception {
            $mech->submit_form(
                with_fields => { 'xx' => q{} },
            );
        },
        qr/There is no form with the requested fields/,
        'submit_form with no match (1)',
    );
}

{
    $mech->get($uri);
    like(
        exception {
            $mech->submit_form(
                with_fields => { '1a' => q{} },
                form_number => 2,
            );
        },
        qr/There is no form that satisfies all the criteria/,
        'submit_form with no match (2)',
    );
}

{
    $mech->get($uri);
    like(
        exception {
            $mech->submit_form(
                form_number => 2,
                form_name   => '3rd_form_ambiguous',
            );
        },
        qr/There is no form that satisfies all the criteria/,
        'submit_form with no match (3)',
    );
}

{
    $mech->get($uri);
    like(
        exception {
            $mech->submit_form(
                form_name => '3rd_form_ambiguous',
            );
        },
        qr/More than one form satisfies all the criteria/,
        'submit_form with more than one match',
    );
}

{
    $mech->get($uri);
    is(
        exception {
            $mech->submit_form(
                with_fields => { 'x' => q{} },
                form_name   => '3rd_form_ambiguous',
            );
        },
        undef,
        'submit_form with intersection of two criteria',
    );
}

{
    $mech->get($uri);
    is(
        exception {
            $mech->submit_form(
                with_fields => { '1b' => q{}, 'opt[2]' => q{} },
            );
        },
        undef,
        ' submit_form( with_fields => %data ) ',
    );
}

{
    $mech->get($uri);
    like(
        exception {
            $mech->submit_form(
                form_name => '1st_form',
                fields    => {
                    '1c' => 'madeup_field',
                },
            );
        },
        qr/^No such field '1c'/,
        'submit_form with invalid field and with global strict_forms and without implicit strict_forms fails',
    );
}

{
    $mech->get($uri);
    like(
        exception {
            $mech->submit_form(
                form_name => '1st_form',
                fields    => {
                    '1c' => 'madeup_field',
                },
                strict_forms => 1,
            );
        },
        qr/^No such field '1c'/,
        'submit_form with invalid field and with global strict_forms and with implicit strict_forms fails',
    );
}

{
    $mech->get($uri);
    like(
        exception {
            $mech->submit_form(
                form_name => '1st_form',
                fields    => {
                    '1c' => 'madeup_field',
                },
                strict_forms => 1,
            );
        },
        qr/^No such field '1c'/,
        'submit_form with invalid field and strict_forms option fails',
    );
}

{
    $mech->get($uri);
    is(
        exception {
            $mech->submit_form(
                form_name => '1st_form',
                fields    => {
                    '1a' => 'value1',
                    '1b' => 'value2',
                },
                strict_forms => 1,
            );
        },
        undef,
        'submit_form with valid fields and strict_forms option succeeds',
    );
}

{
    $mech->get($uri);
    is(
        exception {
            $mech->submit_form(
                form_name => '1st_form',
                fields    => {
                    '1c' => 'madeup_field',
                },
                strict_forms => 0,
            );
        },
        undef,
        'submit_form with invalid field and with global strict_forms and with implicit disabled strict_forms succeeds',
    );
}

{
    $mech->get(
        URI::file->new_abs('t/form_with_fields_verbose.html')->as_string );
    my $form;
    cmp_deeply(
        [ warnings { $form = $mech->form_with_fields(qw/1a/) } ],
        [ re(qr/foobar/) ],
        'verbose_fields catches wrong HTML',
    );
    isa_ok( $form, 'HTML::Form' );
    is( $form->attr('name'), '1st_form', '... and form matches' );
}
