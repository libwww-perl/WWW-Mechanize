#!perl -T

use warnings;
use strict;

use Test::Exception;
use Test::More;
use WWW::Mechanize ();

dies_ok {
    WWW::Mechanize->new->die('OH NO!  ERROR!');
}
'Expecting to die';

lives_ok {
    WWW::Mechanize->new( onerror => undef )->die('OH NO!  ERROR!');
}
'Not expecting to die';

done_testing();
