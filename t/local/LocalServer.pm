package LocalServer;

# start a fake webserver, fork, and connect to ourselves
use strict;
use Test::More;
use LWP::Simple;
use FindBin;
use File::Spec;
use File::Temp;
use URI::URL qw();
use Carp qw(carp croak);

=head2 C<< Test::HTTP::LocalServer->spawn %ARGS >>

This spawns a new HTTP server. The server will stay running until
C<< $server->stop >> is called.

Valid arguments are:

=over 4

=item * html

scalar containing the page to be served

=item * file

filename containing the page to be served

=item * debug

Set to true to make the spawned server output debug information

=back

All served HTML will have the first %s replaced by the current location.

=cut

sub spawn {
  my ($class,%args) = @_;
  my $self = { %args };
  bless $self,$class;

  local $ENV{TEST_HTTP_VERBOSE} = 1
    if (delete $args{debug});

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
  my $web_page = delete $args{file};
  if (defined $web_page) {
    $web_page = qq{"$web_page"}
  } else {
    $web_page = "";
  };

  my $server_file = File::Spec->catfile( $FindBin::Bin,'log-server' );

  open my $server, qq'$^X "$server_file" "$web_page" "$logfile" |'
    or die "Couldn't spawn fake server $server_file : $!";
  my $url = <$server>;
  chomp $url;
  die "Couldn't find fake server url" unless $url;

  $self->{_fh} = $server;

  my $lhurl = URI::URL->new( $url );
  $lhurl->host( "localhost" );
  $self->{_server_url} = $lhurl;

  diag "Started $lhurl";

  $self;
};

=head2 C<< $server->port >>

This returns the port of the current server. As new instances
will most likely run under a different port, this is convenient
if you need to compare results from two runs.

=cut

sub port {
  carp __PACKAGE__ . "::port called without a server" unless $_[0]->{_server_url};
  $_[0]->{_server_url}->port
};

=head2 C<< $server->url >>

This returns the url where you can contact the server. This url
is valid until you call
C<< $server->stop >>
or
C<< $server->get_output >>

=cut

sub url {
  my $url = $_[0]->{_server_url}->abs;

  return $url->as_string;
};

=head2 C<< $server->stop >>

This stops the server process by requesting a special
url.

=cut

sub stop {
  get( $_[0]->{_server_url} . "quit_server" );
  undef $_[0]->{_server_url}
};

=head2 C<< $server->get_output >>

This stops the server by calling C<stop> and then returns the
output of the server process. This output will be a list of
all requests made to the server concatenated together
as a string.

=cut

sub get_output {
  my ($self) = @_;
  $self->stop;
  local $/;
  local *LOG;
  open LOG, "<", $self->{logfile}
    or die "Couldn't retrieve logfile";
  join "", <LOG>;
}

sub DESTROY {
    my $self = shift;
    $self->stop if $self->{_server_url};
    if ( $self->{_fh} ) {
        close $self->{_fh};
        delete $self->{_fh};
    }
    for my $file ( @{$self->{delete}} ) {
        unlink $file or warn "Couldn't remove tempfile $file : $!\n";
    }
}

=head1 EXPORT

None by default.

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Copyright (C) 2003 Max Maischein

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

Please contact me if you find bugs or otherwise improve the module. More tests are also very welcome !

=head1 SEE ALSO

L<WWW::Mechanize>,L<WWW::Mechanize::Shell>

=cut

1;
