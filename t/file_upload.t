use strict;
use warnings;
use Test::More;
use Test::Fatal qw(lives_ok);
use WWW::Mechanize ();
use URI::file ();

my $file     = 't/file_upload.html';
my $filename = 'the_file_upload.html';
my $mc = WWW::Mechanize->new;
my $uri = URI::file->new_abs( 't/file_upload.html' )->as_string;
my ($form, $input, $as_string);

# &field
$mc->get( $uri );
$mc->field( 'document', [$file] );
($form) = $mc->forms;
$as_string = $form->make_request->as_string;
like( $as_string, qr! filename="$file" !x,
      q/$mc->field( 'document', [$file] )/ );
like(
    $as_string, qr!<form method="post" enctype="multipart/form-data"!,
    '... and the file was sent'
);

$mc->get( $uri );
$mc->field( 'document', [$file, $filename] );
($form) = $mc->forms;
like( $form->make_request->as_string, qr! filename="$filename" !x,
      q/$mc->field( 'document', [$file, $filename] )/ );

$mc->get( $uri );
$mc->field( 'document', [$file, $filename, Content => 'changed content'] );
($form) = $mc->forms;
$as_string = $form->make_request->as_string;
like( $as_string, qr! filename="$filename" !x,
      q/$mc->field( 'document', [$file, $filename, Content => 'changed content'] )/ );
like(
    $as_string, qr!changed content!,
    '... and the Content header was sent instead of the file'
);


# &set_fields

$mc->get( $uri );
$mc->set_fields( 'document' => [$file] );
($form) = $mc->forms;
$as_string = $form->make_request->as_string;
like( $as_string, qr! filename="$file" !x,
      q/$mc->set_fields( 'document', [$file] )/ );
like(
    $as_string, qr!<form method="post" enctype="multipart/form-data"!,
    '... and the file was sent'
);

$mc->get( $uri );
$mc->set_fields( 'document' => [ $file, $filename ] );
($form) = $mc->forms;
like( $form->make_request->as_string, qr! filename="$filename" !x,
      q/$mc->set_fields( 'document' => [ $file, $filename ] )/ );

$mc->get( $uri );
$mc->set_fields( 'document' => [ $file, $filename, Content => 'my content' ] );
($form) = $mc->forms;
$as_string = $form->make_request->as_string;
like( $as_string, qr! filename="$filename" !x,
      q/$mc->set_fields( 'document' => [ $file, $filename, Content => 'my content' ] )/ );
like(
    $as_string, qr!my content!,
    '... and the Content header was sent instead of the file'
);

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

$mc->get( $uri );
$mc->set_fields
  ( 'document' => [[ undef, $filename, Content => 'content' ], 1] );
($form) = $mc->forms;
$as_string = $form->make_request->as_string;
like( $as_string, qr! filename="$filename" !x,
      q/$mc->set_fields( 'document' => [[ undef, $filename, Content => 'content' ], 1] )/ );

# &set_fields with multiple fields
$mc->get( $uri );
$mc->set_fields( 'another_field' => 'foo', 'document' => [ $file, $filename ] );
($form) = $mc->forms;
like( $form->make_request->as_string, qr! filename="$filename" !x,
      q/$mc->set_fields( 'another_field' => 'foo', 'document' => [ $file, $filename ] )/ );


# field does not exist
$mc->get( $uri );
lives_ok { $mc->set_fields( 'does_not_exist' => [ [$file], 1 ] ) }
'setting a field that does not exist lives';
($form) = $mc->forms;
$as_string = $form->make_request->as_string;
unlike( $as_string, qr! filename="$file" !x,
      q/$mc->set_fields( 'does_not_exist' => [ [$file], 1 ] )/ );

done_testing;
