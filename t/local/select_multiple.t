use warnings;
use strict;
use Test::More;
use Test::Exception;

use lib 't/local';
use LocalServer;

BEGIN {
    use_ok( 'WWW::Mechanize' );
    delete @ENV{ qw( http_proxy HTTP_PROXY ) };
    delete @ENV{ qw( IFS CDPATH ENV BASH_ENV ) };

}

my $mech = WWW::Mechanize->new(cookie_jar => {});
isa_ok( $mech, "WWW::Mechanize" );
ok(defined($mech->cookie_jar()),
   'this $mech starts with a cookie jar');

my $html = <<'HTML';
<html>
<head><title>%s</title></head>
<body>Whatever.
    <form action="foo.thing">
        <select name="chanId" MULTIPLE>
            <option value="130" selected>Anime Network</option>
            <option value="119" >COM 250</option>
        </select>
    </form>
</body>
</html>
HTML

my $server = LocalServer->spawn( html => $html );
isa_ok( $server, "LocalServer" );

dies_ok { $mech->submit_form( form_number => 1, fields => { none => 0 } ) }
'Dies without a form';

$mech->get($server->url);
ok( $mech->success, 'Fetched OK' );

eval {
    $mech->submit_form(
        form_number => 1,
        fields => {
            chanId => 119,
        }
    );
};
is( $@, '', 'submit_form, second value' );
like( $mech->uri, qr/chanId=119/, '... and the second value was set');

eval {
    $mech->form_number(1);
    $mech->set_fields(
            chanId => 119,
    );
};
is( $@, '', 'set_fields, second value' );
like( $mech->uri, qr/chanId=119/, '... and the second value was set');


eval {
    $mech->submit_form(
        form_number => 1,
        fields => {
            chanId => [119],
        }
    );
};
is( $@, '', 'submit_form, second value as array' );
like( $mech->uri, qr/chanId=119/, '... and the second value was set');


eval {
    $mech->form_number(1);
    $mech->field(
            chanId => 119,
    );
    $mech->submit;
};
is( $@, '', 'field, second value' );
like( $mech->uri, qr/chanId=119/, '... and the second value was set');


eval {
    $mech->form_number(1);
    $mech->field(
            chanId => [119],
    );
    $mech->submit;
};
is( $@, '', 'field, second value as array' );
like( $mech->uri, qr/chanId=119/, '... and the second value was set');


eval {
    $mech->submit_form(
        form_number => 1,
        fields => {
            chanId => 130,
        }
    );
};
is( $@, '', 'submit_form, first value' );
like( $mech->uri, qr/chanId=130/, '... and the first value was set');


SKIP: {
    eval "use Test::Memory::Cycle";
    skip "Test::Memory::Cycle not installed", 1 if $@;

    memory_cycle_ok( $mech, "No memory cycles found" );
}

done_testing;