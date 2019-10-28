requires "Carp" => "0";
requires "Getopt::Long" => "0";
requires "HTML::Form" => "1.00";
requires "HTML::HeadParser" => "0";
requires "HTML::TokeParser" => "0";
requires "HTML::TreeBuilder" => "5";
requires "HTTP::Cookies" => "0";
requires "HTTP::Request" => "1.30";
requires "HTTP::Request::Common" => "0";
requires "LWP::UserAgent" => "5.827";
requires "Pod::Usage" => "0";
requires "Scalar::Util" => "1.14";
requires "Tie::RefHash" => "0";
requires "URI::URL" => "0";
requires "URI::file" => "0";
requires "base" => "0";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "CGI" => "4.32";
  requires "Exporter" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "FindBin" => "0";
  requires "HTTP::Daemon" => "6.05";
  requires "HTTP::Response" => "0";
  requires "HTTP::Server::Simple::CGI" => "0";
  requires "LWP" => "0";
  requires "LWP::Simple" => "0";
  requires "Test::Deep" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0.96";
  requires "Test::Output" => "0";
  requires "Test::Warnings" => "0";
  requires "URI" => "0";
  requires "URI::Escape" => "0";
  requires "bytes" => "0";
  requires "lib" => "0";
  requires "vars" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'configure' => sub {
  suggests "JSON::PP" => "2.27300";
};

on 'develop' => sub {
  requires "Code::TidyAll" => "0.71";
  requires "Code::TidyAll::Plugin::SortLines::Naturally" => "0.000003";
  requires "Code::TidyAll::Plugin::Test::Vars" => "0.04";
  requires "Code::TidyAll::Plugin::UniqueLines" => "0.000003";
  requires "Encode" => "0";
  requires "Parallel::ForkManager" => "1.19";
  requires "Perl::Critic" => "1.132";
  requires "Perl::Tidy" => "20180220";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::Code::TidyAll" => "0.50";
  requires "Test::Memory::Cycle" => "1.06";
  requires "Test::More" => "0.88";
  requires "Test::Needs" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::RequiresInternet" => "0";
  requires "Test::Vars" => "0.014";
  requires "constant" => "0";
  requires "lib" => "0";
};

on 'develop' => sub {
  recommends "Dist::Zilla::PluginBundle::Git::VersionManager" => "0.007";
};
