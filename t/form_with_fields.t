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
            with_fields => { 'xx' => '' },
        ); };
    like($@, qr/There is no form with the requested fields/, 'submit_form with no match (1)' );
}

{
    $mech->get($uri);
    eval { $mech->submit_form(
            with_fields => { '1a' => '' },
            form_number => 2,
        ); };
    like($@, qr/There is no form that satisfies all the criteria/, 'submit_form with no match (2)' );
}

{
    $mech->get($uri);
    eval { $mech->submit_form(
            form_number => 2,
            form_name => '3rd_form_ambiguous',
        ); };
    like($@, qr/There is no form that satisfies all the criteria/, 'submit_form with no match (3)' );
}

{
    $mech->get($uri);
    eval { $mech->submit_form(
            form_name => '3rd_form_ambiguous',
        ); };
    like($@, qr/More than one form satisfies all the criteria/, 'submit_form with more than one match' );
}

{
    $mech->get($uri);
    eval { $mech->submit_form(
            with_fields => { 'x' => '' },
            form_name => '3rd_form_ambiguous',
        ); };
    is($@, '', 'submit_form with intersection of two criteria' );
}

{
    $mech->get($uri);
    eval { $mech->submit_form( 
            with_fields => { '1b' => '', 'opt[2]' => '' },
        ); };
    is($@,'', ' submit_form( with_fields => %data ) ' );
}
