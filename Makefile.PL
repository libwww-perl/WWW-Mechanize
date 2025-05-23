# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Handy web browsing in a Perl object",
  "AUTHOR" => "Andy Lester <andy at petdance.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "WWW-Mechanize",
  "EXE_FILES" => [
    "script/mech-dump"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008",
  "NAME" => "WWW::Mechanize",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Getopt::Long" => 0,
    "HTML::Form" => "6.08",
    "HTML::HeadParser" => 0,
    "HTML::TokeParser" => 0,
    "HTML::TreeBuilder" => 5,
    "HTTP::Cookies" => 0,
    "HTTP::Request" => "1.30",
    "HTTP::Request::Common" => 0,
    "LWP::UserAgent" => 0,
    "Pod::Usage" => 0,
    "Tie::RefHash" => 0,
    "URI::URL" => 0,
    "URI::file" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "HTTP::Daemon" => "6.12",
    "LWP" => 0,
    "LWP::Simple" => 0,
    "Path::Tiny" => 0,
    "Test::Deep" => 0,
    "Test::Fatal" => 0,
    "Test::Memory::Cycle" => 0,
    "Test::More" => "0.96",
    "Test::Output" => 0,
    "Test::Warnings" => 0,
    "URI" => 0,
    "URI::Escape" => 0,
    "bytes" => 0,
    "lib" => 0
  },
  "VERSION" => "2.20",
  "test" => {
    "TESTS" => "t/*.t t/local/*.t t/mech-dump/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "File::Temp" => 0,
  "FindBin" => 0,
  "Getopt::Long" => 0,
  "HTML::Form" => "6.08",
  "HTML::HeadParser" => 0,
  "HTML::TokeParser" => 0,
  "HTML::TreeBuilder" => 5,
  "HTTP::Cookies" => 0,
  "HTTP::Daemon" => "6.12",
  "HTTP::Request" => "1.30",
  "HTTP::Request::Common" => 0,
  "LWP" => 0,
  "LWP::Simple" => 0,
  "LWP::UserAgent" => 0,
  "Path::Tiny" => 0,
  "Pod::Usage" => 0,
  "Test::Deep" => 0,
  "Test::Fatal" => 0,
  "Test::Memory::Cycle" => 0,
  "Test::More" => "0.96",
  "Test::Output" => 0,
  "Test::Warnings" => 0,
  "Tie::RefHash" => 0,
  "URI" => 0,
  "URI::Escape" => 0,
  "URI::URL" => 0,
  "URI::file" => 0,
  "bytes" => 0,
  "lib" => 0,
  "parent" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
