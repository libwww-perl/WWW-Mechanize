use Test::More;
eval "use Test::Pod::Coverage 0.02";
plan skip_all => "Test::Pod::Coverage 0.02 required for testing POD coverage" if $@;

plan tests=>2;

pod_coverage_ok( "WWW::Mechanize" );
pod_coverage_ok( "WWW::Mechanize::Link" );
