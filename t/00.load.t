# $Id: 00.load.t,v 1.3 2003/11/27 03:26:13 petdance Exp $

use Test::More tests => 2;

use_ok( 'WWW::Mechanize' );
use_ok( 'WWW::Mechanize::Link' );

diag( "Testing WWW::Mechanize $WWW::Mechanize::VERSION" );
