#!perl -T

use warnings;
use strict;

use Test::Fatal qw( exception );
use Test::More;
use WWW::Mechanize ();

my $bad_url = "file:///foo.foo.xx.random";

AUTOCHECK_OFF: {
  my $mech = WWW::Mechanize->new( autocheck => 0 );
  ok( !$mech->autocheck, q{Autocheck is set to off via new()} );

  $mech->get($bad_url);
  ok( !$mech->success, qq{Didn't fetch $bad_url, but didn't die, either} );

  $mech->autocheck(1);
  ok( $mech->autocheck, q{Autocheck is now on} );
  like( exception { $mech->get($bad_url) },
        qr/Error GETing/,
        qq{... and couldn't fetch $bad_url, and died as a result} );
}

AUTOCHECK_ON: {
  my $mech = WWW::Mechanize->new;
  ok( $mech->autocheck, q{Autocheck is on by default} );

  like( exception { $mech->get($bad_url) },
        qr/Error GETing/,
        qq{Couldn't fetch $bad_url, and died as a result} );

  $mech->autocheck(0);
  ok( !$mech->autocheck, q{Autocheck is now off} );

  $mech->get($bad_url);
  ok( !$mech->success,
      qq{... and didn't fetch $bad_url, but didn't die, either} );
}

done_testing();
