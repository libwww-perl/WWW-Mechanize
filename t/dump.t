#!perl

use warnings;
use strict;

use File::Spec ();
use File::Temp qw( tempdir );
use Test::More 0.96 tests => 7;
use Test::Output qw( stdout_is stdout_like );
use URI::file ();

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

my $dir = tempdir( CLEANUP => 1 );

subtest "dump_headers", sub {
	plan tests => 5;
	my $mech     = create_mech('t/find_inputs.html');
	my $tmp_name = File::Spec->catfile($dir, 'headers.tmp');

	$mech->dump_headers($tmp_name);
	ok( -e $tmp_name, 'Dump file created');

	fh_test($mech, 'dump_headers', qr/Content-Length/);
};


subtest "dump_links test", sub {
    dump_tests('dump_links', 't/find_link.html', <<'EXPECTED');
http://www.drphil.com/
HTTP://WWW.UPCASE.COM/
styles.css
foo.png
http://blargle.com/
http://a.cpan.org/
http://b.cpan.org/
foo.html
bar.html
http://c.cpan.org/
http://d.cpan.org/
http://www.msnbc.com/
http://www.oreilly.com/
http://www.cnn.com/
http://www.bbc.co.uk/
http://www.msnbc.com/
http://www.cnn.com/
http://www.bbc.co.uk/
/cgi-bin/MT/mt.cgi
http://www.msnbc.com/area
http://www.cnn.com/area
http://www.cpan.org/area
http://nowhere.org/
http://nowhere.org/padded
blongo.html
http://www.yahoo.com/
EXPECTED
};

subtest "dump_images test", sub {
    dump_tests('dump_images', 't/image-parse.html', <<'EXPECTED');
/Images/bg-gradient.png
wango.jpg
bongo.gif
linked.gif
hacktober.jpg
hacktober.jpg
hacktober.jpg
http://example.org/abs.tif

images/logo.png
inner.jpg
outer.jpg
EXPECTED
};

subtest "dump_forms test", sub {
    dump_tests('dump_forms', 't/form_with_fields.html', <<'EXPECTED');
POST http://localhost/ (multipart/form-data) [1st_form]
  1a=                            (text)
  1b=                            (text)
  submit=Submit                  (submit)

POST http://localhost/ [2nd_form]
  opt[2]=                        (text)
  1b=                            (text)
  submit=Submit                  (submit)

POST http://localhost/ (multipart/form-data) [3rd_form_ambiguous]
  3a=                            (text)
  3b=                            (text)
  submit=Submit                  (submit)

POST http://localhost/ (multipart/form-data) [3rd_form_ambiguous]
  3c=                            (text)
  3d=                            (text)
  x=                             (text)
  submit=Submit                  (submit)

POST http://localhost/ (multipart/form-data) [4th_form_1]
  4a=                            (text)
  4b=                            (text)
  x=                             (text)
  submit=Submit                  (submit)

POST http://localhost/ (multipart/form-data) [4th_form_2]
  4a=                            (text)
  4b=                            (text)
  x=                             (text)
  submit=Submit                  (submit)

POST https://localhost
  5a=                            (hidden readonly)
  5b=value                       (hidden readonly)
  5c=                            (hidden readonly)
  5d=foo                         (hidden readonly)
  5e=value                       (hidden readonly)

EXPECTED
};

subtest "dump_forms multiselect", sub {
    dump_tests('dump_forms', 't/form_133_regression.html', <<'EXPECTED');
GET http://localhost/
  select1=1                      (option)   [*1|2|3|4]
  select2=1                      (option)   [*1|2|3|4]
  select3=1                      (option)   [*1|2|3|4]
  select4=1                      (option)   [*1|2|3|4]
  multiselect1=<UNDEF>           (option)   [*<UNDEF>/off|1]
  multiselect1=<UNDEF>           (option)   [*<UNDEF>/off|2]
  multiselect1=<UNDEF>           (option)   [*<UNDEF>/off|3]
  multiselect1=<UNDEF>           (option)   [*<UNDEF>/off|4]
  multiselect2=<UNDEF>           (option)   [*<UNDEF>/off|1]
  multiselect2=<UNDEF>           (option)   [*<UNDEF>/off|2]
  multiselect2=<UNDEF>           (option)   [*<UNDEF>/off|3]
  multiselect2=<UNDEF>           (option)   [*<UNDEF>/off|4]

EXPECTED
};

subtest "dump_text test", sub {
    dump_tests('dump_text', 't/image-parse.html', <<'EXPECTED');
Testing image extractionblargle And now, the dreaded wango  CNN   BBC Blongo!Logo
EXPECTED
};

sub dump_tests {
	my ($method, $fp, $expected) = @_;
	my $mech     = create_mech($fp);

	fh_test($mech, $method, $expected);
};

sub create_mech {
	my $filepath = shift;
	my $mech     = WWW::Mechanize->new( cookie_jar => undef );
	isa_ok( $mech, 'WWW::Mechanize' );
	my $uri = URI::file->new($filepath)->abs(URI::file->cwd)->as_string;

	$mech->get( $uri );
	ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

	return $mech;
}


sub fh_test {
	my ($mech, $method, $expected) = @_;
    unless($method && $expected) {
        diag("No method/expected value found");
        return;
    }
	my ($content);
	open my $fh, '>', \$content or die ($!);

	$mech->$method( $fh );

	close $fh;

	if (ref $expected eq 'Regexp') {
		like( $content, $expected, 'Dump has valid values');
		stdout_like( sub {$mech->$method()}, $expected, 'Valid STDOUT');
	} else {
		is( $content, $expected, 'Dump has valid values');
		stdout_is  ( sub {$mech->$method()}, $expected, 'Valid STDOUT');
	}
}
