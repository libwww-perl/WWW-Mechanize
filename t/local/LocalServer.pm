package LocalServer;

# start a fake webserver, fork, and connect to ourselves
use warnings;
use strict;
use LWP::Simple;
use FindBin;
use File::Spec;
use File::Temp;
use URI::URL qw();
use Carp qw(carp croak);

use vars qw($VERSION);
$VERSION = '0.55';

=head1 SYNOPSIS

  use LWP::Simple qw(get);
  my $server = Test::HTTP::LocalServer->spawn;

  ok get $server->url, "Retrieve " . $server->url;

  $server->stop;

=head1 METHODS

=head2 C<Test::HTTP::LocalServer-E<gt>spawn %ARGS>

This spawns a new HTTP server. The server will stay running until
C<< $server->stop >> is called.

Valid arguments are:

=over 4

=item *

C<< html => >> scalar containing the page to be served

=item *

C<< file => >> filename containing the page to be served

=item *

C<<  debug => 1 >> to make the spawned server output debug information

=item *

C<<  eval => >> string that will get evaluated per request in the server

Try to avoid characters that are special to the shell, especially quotes.
A good idea for a slow server would be

  eval => sleep+10

=back

All served HTML will have the first %s replaced by the current location.

The following entries will be removed from C<%ENV>:

    HTTP_PROXY
    http_proxy
    CGI_HTTP_PROXY

=cut

sub spawn {
  my ($class,%args) = @_;
  my $self = { %args };
  bless $self,$class;

  local $ENV{TEST_HTTP_VERBOSE};
  $ENV{TEST_HTTP_VERBOSE} = 1
    if (delete $args{debug});

  delete @ENV{qw(HTTP_PROXY http_proxy CGI_HTTP_PROXY)};

  $self->{delete} = [];
  if (my $html = delete $args{html}) {
    # write the html to a temp file
    my ($fh,$tempfile) = File::Temp::tempfile();
    binmode $fh;
    print $fh $html
      or die "Couldn't write tempfile $tempfile : $!";
    close $fh;
    push @{$self->{delete}},$tempfile;
    $args{file} = $tempfile;
  };
  my ($fh,$logfile) = File::Temp::tempfile();
  close $fh;
  push @{$self->{delete}},$logfile;
  $self->{logfile} = $logfile;
  my $web_page = delete $args{file} || "";

  my $server_file = File::Spec->catfile( $FindBin::Bin,'log-server' );
  my @opts;
  push @opts, "-e" => qq{"} . delete($args{ eval }) . qq{"}
      if $args{ eval };

  my $pid = open my $server, qq'$^X "$server_file" "$web_page" "$logfile" @opts|'
    or croak "Couldn't spawn local server $server_file : $!";
  my $url = <$server>;
  chomp $url;
  die "Couldn't read back local server url"
      unless $url;

  # What is this code supposed to fix?
  my $lhurl = URI::URL->new( $url );
  $lhurl->host( 'localhost' );
  $self->{_server_url} = $lhurl;
  
  $self->{_fh} = $server;
  $self->{_pid} = $pid;

  $self;
};

=head2 C<< $server->port >>

This returns the port of the current server. As new instances
will most likely run under a different port, this is convenient
if you need to compare results from two runs.

=cut

sub port {
  carp __PACKAGE__ . '::port called without a server' unless $_[0]->{_server_url};
  $_[0]->{_server_url}->port
};

=head2 C<< $server->url >>

This returns the url where you can contact the server. This url
is valid until the C<$server> goes out of scope or you call
C<< $server->stop >> or C<< $server->get_log >>.

=cut

sub url {
  $_[0]->{_server_url}->abs->as_string
};

=head2 C<< $server->stop >>

This stops the server process by requesting a special
url.

=cut

sub stop {
    my ($self) = @_;
    get( $self->quit_server );
    undef $self->{_server_url};
    if ( $self->{_fh} ) {
        close $self->{_fh};
        delete $self->{_fh};
    }
};

=head2 C<< $server->kill >>

This kills the server process via C<kill>. The log
cannot be retrieved then.

=cut

sub kill {
  CORE::kill( 9 => $_[0]->{ _pid } );
  undef $_[0]->{_server_url};
  undef $_[0]->{_pid};
};

=head2 C<< $server->get_log >>

This stops the server by calling C<stop> and then returns the
output of the server process. This output will be a list of
all requests made to the server concatenated together
as a string.

=cut

sub get_log {
  my ($self) = @_;
  
  my $log = get( $self->get_server_log );
  $self->stop;
  return $log;
};

sub DESTROY {
  $_[0]->stop if $_[0]->{_server_url};
  for my $file (@{$_[0]->{delete}}) {
    unlink $file or warn "Couldn't remove tempfile $file : $!\n";
  };
};

=head1 URLs implemented by the server

=head2 302 redirect C<< $server->redirect($target) >>

This URL will issue a redirect to C<$target>. No special care is taken
towards URL-decoding C<$target> as not to complicate the server code.
You need to be wary about issuing requests with escaped URL parameters.

=head2 404 error C<< $server->error_notfound($target) >>

This URL will response with status code 404.

=head2 Timeout C<< $server->error_timeout($seconds) >>

This URL will send a 599 error after C<$seconds> seconds.

=head2 Timeout+close C<< $server->error_close($seconds) >>

This URL will send nothing and close the connection after C<$seconds> seconds.

=head2 Error in response content C<< $server->error_after_headers >>

This URL will send headers for a successfull response but will close the
socket with an error after 2 blocks of 16 spaces have been sent.

=head2 Chunked response C<< $server->chunked >>

This URL will return 5 blocks of 16 spaces at a rate of one block per second
in a chunked response.

=head2 Other URLs

All other URLs will echo back the cookies and query parameters.

=cut

use vars qw(%urls);
%urls = (
    'quit_server' => 'quit_server',
    'get_server_log' => 'get_server_log',
    'redirect' => 'redirect/%s',
    'error_notfound' => 'error/notfound/%s',
    'error_timeout' => 'error/timeout/%s',
    'error_close' => 'error/close/%s',
    'error_after_headers' => 'error/after_headers',
    'chunked' => 'chunks',
);
for (keys %urls) {
    no strict 'refs';
    my $name = $_;
    *{ $name } = sub {
        my $self = shift;
        $self->url . sprintf $urls{ $name }, @_;
    };
};

=head1 EXPORT

None by default.

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Copyright (C) 2003-2011 Max Maischein

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

Please contact me if you find bugs or otherwise improve the module. More tests are also very welcome !

=head1 SEE ALSO

L<WWW::Mechanize>,L<WWW::Mechanize::Shell>,L<WWW::Mechanize::Firefox>

=cut

1;
