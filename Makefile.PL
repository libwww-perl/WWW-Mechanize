use ExtUtils::MakeMaker;


WriteMakefile(
    'NAME'		=> 'WWW::Automate',
    'VERSION_FROM'	=> 'lib/WWW/Automate.pm', # finds $VERSION
    'PREREQ_PM'		=> { # e.g., Module::Name => 1.1
                            LWP::UserAgent => 1.80,
                            HTTP::Request => 1.20,
                            HTML::Form => 0.03,
                            HTML::TokeParser => 2.20,
                            Clone => 0.13,
                            Test::More => 0.34,
			},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/WWW/Automate.pm', # retrieve abstract from module
       AUTHOR     => 'Kirrily "Skud" Robert <skud@cpan.org>') : ()),

);

print "Generating embedded tests...\n";
open(MANIFEST, "MANIFEST");
foreach my $file (grep /\.pm$/, <MANIFEST>) {
	next if $file =~ m(L10N/..\.pm$);		# skip lexicon stubs
	chomp $file;
	my($module) = $file =~ m|^lib/(.*)\.pm$|;
	$module =~ s|/|-|g;
	system("pod2test $file t/embedded-$module.t");
}

