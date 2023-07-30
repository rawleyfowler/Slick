## no critic
use Test::More;

use_ok 'Slick', 'Can use ok?';

require Slick;

my $slick = Slick->new;

isa_ok $slick, 'Slick';

# Test defaults
ok $slick->handlers;
isa_ok $slick->handlers, 'Slick::RouteMap';
is $slick->addr,    '127.0.0.1';
is $slick->port,    8000;
is $slick->timeout, 120;
is $slick->env,     'dev';
ok $slick->server;
isa_ok $slick->server, 'HTTP::Server::PSGI';
ok $slick->dbs;
isa_ok $slick->dbs, 'HASH';
ok $slick->banner;

ok $slick->_event_handlers;
isa_ok $slick->_event_handlers, 'HASH';

my $t = {
    QUERY_STRING    => "",
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "GET",
    REQUEST_URI     => "/",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

my $response = $slick->_dispatch($t);

is $response->[0],      '405';
is $response->[2]->[0], '405 Method Not Supported';

$slick->get(
    '/foo',
    sub {
        my ( $app, $context ) = @_;
        $context->status(201)->json( { foo => 'bar' } );
    }
);

$slick->post(
    '/foo',
    sub {
        my ( $app, $context ) = @_;
        $context->status(500);
    }
);

$slick->get(
    '/foobar',
    sub {
        # unreachable
    },
    {
        before_dispatch => [
            sub {
                my ( $app, $context ) = @_;
                $context->status(509);

                # Fail
                return undef;
            }
        ]
    }
);

$slick->get(
    '/foo/{bar}',
    sub {
        $_[1]->status(201)->body( $_[1]->param->{'bar'} );
    }
);

$slick->get(
    '/foo/query',
    sub {
        $_[1]->body( $_[1]->query->{'foo'} );
    }
);

ok $slick->handlers->_map->{'/'}->{children}->{'foo'}->{methods}->{post};
ok $slick->handlers->_map->{'/'}->{children}->{'foo'}->{methods}->{get};
ok $slick->handlers->_map->{'/'}->{children}->{'foobar'}->{methods}->{get};
my $f = $slick->handlers->_map->{'/'}->{children}->{'foo'}->{methods}->{get};
isa_ok $f, 'Slick::Route';
$f = $slick->handlers->_map->{'/'}->{children}->{'foo'}->{methods}->{post};
isa_ok $f, 'Slick::Route';
$f = $slick->handlers->_map->{'/'}->{children}->{'foobar'}->{methods}->{get};
isa_ok $f, 'Slick::Route';

$t = {
    QUERY_STRING    => "",
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "GET",
    REQUEST_URI     => "/foo",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

$response = $slick->_dispatch($t);

is $response->[0],      '201';
is $response->[2]->[0], '{"foo":"bar"}';
is %{ { @{ $response->[1] } } }{'Content-Type'},
  'application/json; encoding=utf8';

$t = {
    QUERY_STRING    => "",
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "POST",
    REQUEST_URI     => "/foo",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

$response = $slick->_dispatch($t);

is $response->[0],      '500';
is $response->[2]->[0], '';

$t = {
    QUERY_STRING    => "",
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "GET",
    REQUEST_URI     => "/foobar",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

$response = $slick->_dispatch($t);

is $response->[0],      '509';
is $response->[2]->[0], '';

$t = {
    QUERY_STRING    => "",
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "GET",
    REQUEST_URI     => "/foo/boop",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

$response = $slick->_dispatch($t);

is $response->[0],      '201';
is $response->[2]->[0], 'boop';

$t = {
    QUERY_STRING    => "foo=bar",
    REMOTE_ADDR     => "127.0.0.1",
    REMOTE_PORT     => 46604,
    REQUEST_METHOD  => "GET",
    REQUEST_URI     => "/foo/query",
    SCRIPT_NAME     => "",
    SERVER_NAME     => "127.0.0.1",
    SERVER_PORT     => 8000,
    SERVER_PROTOCOL => "HTTP/1.1"
};

$response = $slick->_dispatch($t);

is $response->[0],      '200';
is $response->[2]->[0], 'bar';

done_testing;
