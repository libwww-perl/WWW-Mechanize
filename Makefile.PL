use ExtUtils::MakeMaker;


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
