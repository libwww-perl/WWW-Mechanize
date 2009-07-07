package Tools;

our $canTMC;

use base 'Exporter';

our @EXPORT_OK = qw( $canTMC );
our @EXPORT    = @EXPORT_OK;

sub import {
    delete @ENV{ qw( http_proxy HTTP_PROXY PATH IFS CDPATH ENV BASH_ENV) };

    if ( eval 'use Test::Memory::Cycle' ) {
        $canTMC = !$@;
    }
    else {
        $canTMC = 0;
    }
    Tools->export_to_level(1, @_);
}


1;
