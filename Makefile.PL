use ExtUtils::MakeMaker qw( WriteMakefile prompt );
use strict;

use constant FLAG_SKIPMECHFORMS => "t/SKIP-MECH-FORMS";
use constant FLAG_SKIPLIVE => "t/SKIP-LIVE";

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

It seems that you are not directly connected to the Internet.  Many of 
the WWW::Mechanize tests interact with websites such as Google.

EOT

    if ( prompt("Do you want to skip these tests?", "y") =~ /^y/i ) {
	$skiplive = 1;
    }
} # failed connect

if ( $skiplive ) {
    touch( FLAG_SKIPLIVE );
} else {
    unlink FLAG_SKIPLIVE;
}

no strict;
my $parms = {
    'NAME'	    => 'WWW::Mechanize',
    'VERSION_FROM'  => 'lib/WWW/Mechanize.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/WWW/Mechanize.pm', # retrieve abstract from module
    'AUTHOR'	    => 'Andy Lester <andy@petdance.com>',
    'PREREQ_PM'	    => { # e.g., Module::Name => 1.1
			FindBin		    => 0,
			HTML::HeadParser    => 0,
			HTTP::Daemon	    => 0,
			HTTP::Status	    => 0,
			LWP		    => 5.69,
			LWP::UserAgent	    => 2.003,
			URI::URL	    => 0,
			URI::file	    => 0,
                        HTML::Form	    => 1.00,
                        HTML::TokeParser    => 2.20,
                        HTTP::Request	    => 1.30,
                        Test::More	    => 0.34,
			},
};

my $skipforms = "t/SKIP-MECH-FORMS";
if ( prompt( "Do you want to install the mech-forms utility?", "y" ) =~ /^y/i ) {
    $parms->{EXE_FILES} = [ 'script/mech-forms' ];
    unlink( FLAG_SKIPMECHFORMS );
} else {
    touch( FLAG_SKIPMECHFORMS );
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

sub touch {
    my $filename = shift;

    local *FH;
    open( FH, ">$filename" ) or die "Can't create $filename";
    close FH;
}
