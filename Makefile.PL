use ExtUtils::MakeMaker qw( WriteMakefile prompt );
use ExtUtils::Command qw( touch rm_f );
use strict;

use constant FLAG_SKIPMECHDUMP => File::Spec->catfile( "t", "SKIP-MECH-DUMP" );

# Much logic stolen fromm libwww-perl's Makefile.PL
my $skiplive = 0;

require IO::Socket;
my $s = IO::Socket::INET->new(PeerAddr => "www.google.com:80",
			      Timeout  => 10,
			     );
if ($s) {
    close($s);
    $skiplive = 0;
} else {
    print <<EOT;

It seems that you are not directly connected to the Internet.  Some
of the WWW::Mechanize tests interact with websites such as Google,
in addition to its own internal tests.

EOT

    if ( prompt("Do you want to skip these tests?", "y") =~ /^y/i ) {
	$skiplive = 1;
    }
} # failed connect

my @tests = File::Spec->catfile( 't', '*.t' );
push( @tests, File::Spec->catfile( 't', 'live', '*.t' ) ) unless $skiplive;

my $parms = {
    'NAME'	    => 'WWW::Mechanize',
    'VERSION_FROM'  => 'lib/WWW/Mechanize.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/WWW/Mechanize.pm', # retrieve abstract from module
    'AUTHOR'	    => 'Andy Lester <andy@petdance.com>',
    'PREREQ_PM'	    => { # e.g., Module::Name => 1.1
                        'File::Temp'        => 0,
                        'FindBin'           => 0,
                        'HTML::Form'        => 1.036,
                        'HTML::HeadParser'  => 0,
                        'HTML::TokeParser'  => 2.28,
                        'HTTP::Daemon'      => 0,
                        'HTTP::Request'     => 1.30,
                        'HTTP::Status'      => 0,
                        'LWP'               => 5.72,
                        'LWP::UserAgent'    => 2.013,
                        'Test::More'        => 0.34,
                        'URI::URL'          => 0,
                        'URI::file'         => 0,
			},
    test	    => { TESTS => join( " ", @tests ) },
    clean	    => { FILES => join( " ", FLAG_SKIPMECHDUMP, 'WWW-Mechanize-0*' ) },
};

if ( prompt( "Do you want to install the mech-dump utility?", "y" ) =~ /^y/i ) {
    $parms->{EXE_FILES} = [ 'script/mech-dump' ];
    $parms->{PREREQ_PM}->{'Getopt::Long'} = 0;
    $parms->{PREREQ_PM}->{'Pod::Usage'} = 0;

    local @ARGV = FLAG_SKIPMECHDUMP;
    rm_f();
} else {
    local @ARGV = FLAG_SKIPMECHDUMP;
    touch();
}


eval { require IO::Socket::SSL };
if ( $@ ) {
    print <<EOT;

It looks like you don't have IO::Socket::SSL installed.  You will
not be able to process https:// URLs correctly.

EOT
}

eval { require Carp };
if ( $@ ) {
    print <<EOT;

It seems that you do not have the Carp module installed.  This is
optional, but WWW::Mechanize's warnings will be more useful if Carp
is installed.

EOT
}

WriteMakefile( %$parms );
