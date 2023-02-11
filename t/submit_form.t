#!perl

use warnings;
use strict;

use Test::More;
use Test::Fatal qw( exception );
use Test::Warnings ':all';
use URI::file      ();
use WWW::Mechanize ();

my $mech = WWW::Mechanize->new( cookie_jar => undef, autocheck => 0 );
my $uri  = URI::file->new_abs('t/form_with_fields.html')->as_string;

$mech->get($uri);

{
    $mech->get($uri);
    like(
        exception {
            $mech->submit_form(
                form_id => 'i-do-not-exist',
            );
        },
        qr/There is no form with ID "i-do-not-exist"/,
        'submit_form with no match on form_id',
    );
}

{
    $mech->get($uri);
    is(
        exception {
            $mech->submit_form(
                form_id => '6th_form',
            );
        },
        undef,
        'submit_form with valid form_id',
    );
}

{
    $mech->get($uri);
    like(
        exception {
            $mech->submit_form(
                form_thing => 'i-do-not-exist',
            );
        },
        qr/Unknown submit_form parameter "form_thing"/,
        'submit_form with invalid arg',
    );
}

{
    $mech->get($uri);
    like(
        exception {
            $mech->submit_form(
                form_number => 99,
            );
        },
        qr/There is no form numbered 99/,
        'submit_form with invalid form number',
    );
}
{
    $mech->get($uri);
    like(
        exception {
            $mech->submit_form(
                form_name => 99,
            );
        },
        qr/There is no form named "99"/,
        'submit_form with invalid form name',
    );
}

{
    $mech->get($uri);
    like(
        exception {
            $mech->submit_form(
                with_fields => [ 'foo', 'bar' ],
            );
        },
        qr/with_fields arg to submit_form must be a hashref/,
        'submit_form with invalid arg value for with_fields',
    );
}

{
    $mech->get($uri);
    like(
        exception {
            $mech->submit_form(
                fields => [ 'foo', 'bar' ],
            );
        },
        qr/fields arg to submit_form must be a hashref/,
        'submit_form with invalid arg value for fields',
    );
}

{
    $mech->get($uri);
    like(
        exception {
            $mech->submit_form(
                with_fields => {},    # left empty on purpose
            )
        },
        qr/no fields provided/,
        'submit_form with no fields',
    );
}

done_testing();
