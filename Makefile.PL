use ExtUtils::MakeMaker qw( WriteMakefile prompt );
use strict;

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

my $filename = "t/SKIPLIVE";
if ( $skiplive ) {
    open( F, ">$filename" ) or die "Can't create $filename";
    close F;
} else {
    unlink $filename;
}

no strict;
WriteMakefile(
    'NAME'	    => 'WWW::Mechanize',
    'VERSION_FROM'  => 'lib/WWW/Mechanize.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/WWW/Mechanize.pm', # retrieve abstract from module
    'AUTHOR'	    => 'Andy Lester <andy@petdance.com>',
    'PREREQ_PM'	    => { # e.g., Module::Name => 1.1
			LWP		    => 5.69,
			LWP::UserAgent	    => 1.80,
                        HTTP::Request	    => 1.20,
                        HTML::Form	    => 0.03,
			HTML::HeadParser    => 0,
                        HTML::TokeParser    => 2.20,
                        Test::More	    => 0.34,
			URI::URL	    => 0,
			URI::file	    => 0,
			HTTP::Daemon	    => 0,
			HTTP::Status	    => 0,
			Carp		    => 0,
			},
);
