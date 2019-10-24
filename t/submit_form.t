#!perl

use warnings;
use strict;

use Test::More;
use Test::Fatal;
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

done_testing();
