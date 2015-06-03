#!perl -T

use warnings;
use strict;

use Test::More tests => 8;
use URI::file;

BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};  # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'WWW::Mechanize' );
}

my $mech = WWW::Mechanize->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Mechanize' );

my $original = 't/find_inputs.html';
my $saved = 'saved1.test.txt';

my $uri = URI::file->new_abs( $original )->as_string;

$mech->get( $uri );
ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

#unlink $saved;
ok( !-e $saved, "$saved does not exist" );
$mech->save_content( $saved );

my $old_text = slurp( $original );
my $new_text = slurp( $saved );

ok( $old_text eq $new_text, 'Saved copy matches the original' ) && unlink $saved;

{
    my $original = 't/save_content.html';
    my $saved = 'saved2.test.txt';

    my $uri = URI::file->new_abs( $original )->as_string;

    $mech->get( $uri );
    ok( $mech->success, "Fetched $uri" ) or die q{Can't get test page};

    #unlink $saved;
    ok( !-e $saved, "$saved does not exist" );
    $mech->save_content( $saved, binary => 1 );

    my $old_text = slurp( $original );
    my $new_text = slurp( $saved );

    ok( $old_text eq $new_text, 'Saved copy matches the original' ) && unlink $saved;
}

sub slurp {
    my $name = shift;

    open( my $fh, '<', $name ) or die "Can't open $name: $!\n";
    return join '', <$fh>;
}
