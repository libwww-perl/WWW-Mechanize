require 5.6.1;
use ExtUtils::MakeMaker qw( WriteMakefile prompt );
use ExtUtils::Command qw( touch rm_f );
use File::Spec;
use strict;

use constant FLAG_SKIPMECHDUMP => File::Spec->catfile( "t", "SKIP-MECH-DUMP" );

# Much logic stolen fromm libwww-perl's Makefile.PL
my $skiplive = grep /--nolive/i, @ARGV;
my $skiplocal = grep /--nolocal/i, @ARGV;

if ( !$skiplive ) {
    require IO::Socket;
    my $s = IO::Socket::INET->new(
        PeerAddr => "www.google.com:80",
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
}

my @tests = glob File::Spec->catfile( 't', '*.t' );
push( @tests, glob File::Spec->catfile( 't', 'local', '*.t' ) ) unless $skiplocal;
push( @tests, glob File::Spec->catfile( 't', 'live', '*.t' ) ) unless $skiplive;

my $parms = {
    'NAME'          => 'WWW::Mechanize',
    'VERSION_FROM'  => 'lib/WWW/Mechanize.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/WWW/Mechanize.pm', # retrieve abstract from module
    'AUTHOR'        => 'Andy Lester <andy@petdance.com>',
    'PREREQ_PM'     => {
                        'Carp'              => 0,
                        'File::Temp'        => 0,
                        'FindBin'           => 0,
                        'HTML::Form'        => 1.038,
                        'HTML::HeadParser'  => 0,
                        'HTML::TokeParser'  => 2.28,
                        'HTTP::Daemon'      => 0,
                        'HTTP::Request'     => 1.30,
                        'HTTP::Status'      => 0,
                        'LWP'               => 5.76,
                        'LWP::UserAgent'    => 2.024,
                        'Test::More'        => 0.34,
						'URI'			    => 1.25,		
                        'URI::URL'          => 0,
                        'URI::file'         => 0,
                        },
    test            => { TESTS => join( " ", @tests ) },
    clean           => { FILES => join( " ", FLAG_SKIPMECHDUMP, 'WWW-Mechanize-0*' ) },
};

if ( prompt( "Do you want to install the mech-dump utility?", "y" ) =~ /^y/i ) {
    $parms->{EXE_FILES} = [ 'bin/mech-dump' ];
    $parms->{PREREQ_PM}->{'Getopt::Long'} = 0;
    $parms->{PREREQ_PM}->{'Pod::Usage'} = 0;

    local @ARGV = FLAG_SKIPMECHDUMP;
    rm_f();
} else {
    local @ARGV = FLAG_SKIPMECHDUMP;
    touch();
}

eval { require LWP; };
if ($@ or ! LWP::Protocol::implementor('https') ) {
    print <<EOT;

It looks like you don't have SSL capability (like IO::Socket::SSL) installed. 
You will not be able to process https:// URLs correctly.

EOT
}

my @missing;
my @nice = qw( Test::Pod Test::Memory::Cycle Test::Warn );
for my $nice ( @nice ) {
    eval "require $nice";
    push( @missing, $nice ) if $@;
}

if ( @missing ) {
    @missing = map { "\t$_\n" } @missing;
    print <<EOT;

WWW::Mechanize likes to have a lot of test modules for some of its tests.
The following are modules that would be nice to have, but not required.

@missing

EOT
}

WriteMakefile( %$parms );
