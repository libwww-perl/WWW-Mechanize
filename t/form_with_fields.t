#!perl -T

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
    my $w; local $mech->{onwarn} = sub { warn $w if defined $w; $w = $_[0] };
    my $form = $mech->form_with_fields('4a', '4b');

    isa_ok( $form, 'HTML::Form' );
    is($form->attr('name'), '4th_form_1', 'fourth form matches');
    is($w, 'There are 2 forms with the named fields.  The first one was used.', 'warning on ambiguous match');
}

{
    my @forms = $mech->all_forms_with( name => '3rd_form_ambiguous' );
    is( scalar @forms, 2 );
    isa_ok( $forms[0], 'HTML::Form' );
    isa_ok( $forms[1], 'HTML::Form' );
    is($forms[0]->attr('name'), '3rd_form_ambiguous', 'first result of 3rd_form_ambiguous');
    is($forms[0]->attr('name'), '3rd_form_ambiguous', 'second result of 3rd_form_ambiguous');
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
