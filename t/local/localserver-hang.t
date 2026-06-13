use warnings;
use strict;

use Test::More;

use lib         qw( t/local );
use LocalServer ();

# A server that stops responding (a wedged child, a dropped loopback
# connection, a proxy that silently swallows the request) used to hang the
# whole test suite: stop() asked the server to quit, then blocked in close()
# waiting on a child that never exited. This makes sure shutdown is now
# always bounded.

plan skip_all => 'POSIX signals required to freeze the server'
    if $^O eq 'MSWin32' || $^O eq 'VMS';

my $server = LocalServer->spawn( html => '<html><body>hi</body></html>' );
my $pid    = $server->{_pid};
ok( $pid, 'spawn started a server and returned its pid' );

# Wedge the server so it cannot answer the quit request and cannot exit on
# its own. close() would then wait on it for ever without the timeout.
ok( kill( 'STOP', $pid ), 'froze the server with SIGSTOP' );

# An independent backstop. stop() installs its own $SIG{ALRM} handlers while
# it runs, so an in-process alarm here could be swallowed by stop() itself.
# Fork a watchdog that stop() cannot silence and have it take the test down
# if shutdown ever runs away.
my $victim   = $$;
my $watchdog = fork;
defined $watchdog or die "couldn't fork watchdog: $!\n";
if ( !$watchdog ) {
    sleep 30;
    kill( 'KILL', $victim );    # stop() hung; bring the test down
    exit 0;
}

my $start = time;
$server->stop;
my $elapsed = time - $start;

# Reaping a process we just SIGKILLed leaves $? set to 9. Older
# Test::Builder reads $? in its END handler and exits with it -- which
# fails this test with no plan -- so localize $? to keep the watchdog's
# death out of our own exit code.
{
    local $?;

    # shutdown returned in time; retire the watchdog
    kill( 'KILL', $watchdog );
    waitpid( $watchdog, 0 );
}

pass('stop() returned instead of hanging');
cmp_ok( $elapsed, '<', 25, "stop() finished promptly (${elapsed}s)" );

done_testing;
