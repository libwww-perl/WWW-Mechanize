use strict;
use warnings;
use Test::More;
use WWW::Mechanize;
use URI::file;

my $file     = 't/file_upload.html';
my $filename = 'the_file_upload.html';
my $mc = WWW::Mechanize->new;
my $uri = URI::file->new_abs( 't/file_upload.html' )->as_string;
my ($form, $input);

# &field

$mc->get( $uri );
$mc->field( 'document', [$file, $filename] );
($form) = $mc->forms;
like( $form->make_request->as_string, qr! filename="$filename" !x,
      q/$mc->field( 'document', [$file, $filename] )/ );

$mc->get( $uri );
$mc->field( 'document', [$file, $filename, Content => 'content'] );
($form) = $mc->forms;
like( $form->make_request->as_string, qr! filename="$filename" !x,
      q/$mc->field( 'document', [$file, $filename, Content => 'content'] )/ );

# &set_fields

$mc->get( $uri );
$mc->set_fields( 'document' => [ $file, $filename ] );
($form) = $mc->forms;
like( $form->make_request->as_string, qr! filename="$filename" !x,
      q/$mc->set_fields( 'document' => [ $file, $filename ] )/ );

$mc->get( $uri );
$mc->set_fields( 'document' => [ $file, $filename, Content => 'content' ] );
($form) = $mc->forms;
like( $form->make_request->as_string, qr! filename="$filename" !x,
      q/$mc->set_fields( 'document' => [ $file, $filename, Content => 'content' ] )/ );

$mc->get( $uri );
$mc->set_fields( 'document' => [[ $file, $filename ], 1] );
($form) = $mc->forms;
like( $form->make_request->as_string, qr! filename="$filename" !x,
      q/$mc->set_fields( 'document' => [[ $file, $filename ], 1] )/ );

$mc->get( $uri );
$mc->set_fields
  ( 'document' => [[ $file, $filename, Content => 'content' ], 1] );
($form) = $mc->forms;
like( $form->make_request->as_string, qr! filename="$filename" !x,
      q/$mc->set_fields( 'document' => [[ $file, $filename, Content => 'content' ], 1] )/ );

done_testing;
