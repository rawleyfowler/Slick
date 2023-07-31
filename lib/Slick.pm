package Slick;

use 5.036;

use Moo;
use Types::Standard qw(HashRef ArrayRef Int Str);
use Module::Runtime qw(require_module);
use Carp            qw(croak);
use URI::Query;
use Plack::Builder qw(builder enable);
use Slick::Context;
use Slick::Events qw(EVENTS BEFORE_DISPATCH AFTER_DISPATCH);
use Slick::Database;
use Slick::Methods qw(METHODS);
use Slick::Route;
use Slick::RouteMap;
use Slick::Util;

our $VERSION = '0.001';

with 'Slick::EventHandler';

foreach my $meth ( @{ METHODS() } ) {
    Slick::Util::monkey_patch(
        __PACKAGE__,
        $meth => sub {
            my ( $self, $route, $callback, $events ) = @_;

            my $route_object = Slick::Route->new(
                callback => $callback,
                route    => $route
            );

            if ($events) {
                foreach my $event ( EVENTS->@* ) {
                    $route_object->on( $event, $_ )
                      for ( @{ $events->{$event} } );
                }
            }

            $self->handlers->add( $route_object, $meth );

            return $route_object;
        }
    );
}

has port => (
    is      => 'ro',
    lazy    => 1,
    isa     => Int,
    default => sub { return 8000; }
);

has addr => (
    is      => 'ro',
    lazy    => 1,
    isa     => Str,
    default => sub { return '127.0.0.1'; }
);

has timeout => (
    is      => 'ro',
    lazy    => 1,
    isa     => Int,
    default => sub { return 120; }
);

has env => (
    is      => 'ro',
    lazy    => 1,
    isa     => Str,
    default => sub {
        return $ENV{SLICK_ENV} || $ENV{PLACK_ENV} || 'dev';
    }
);

has server => (
    is   => 'ro',
    lazy => 1
);

has dbs => (
    is      => 'ro',
    lazy    => 1,
    isa     => HashRef,
    default => sub { return {}; }
);

has handlers => (
    is      => 'rw',
    default => sub { return Slick::RouteMap->new; }
);

has middlewares => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { return []; }
);

has banner => (
    is      => 'rw',
    default => sub {
        return <<'EOB';
a'!   _,,_  a'!  _,,_      a'!   _,,_
  \\_/    \   \\_/    \      \\_/    \.-,
   \, /-( /'-, \, /-( /'-,    \, /-( /
    //\ //\\    //\ //\\       //\ //\\
EOB
    }
);

sub _dispatch {
    require_module 'Plack::Request';

    my $self    = shift;
    my $request = Plack::Request->new(shift);

    my $context = Slick::Context->new( request => $request, );

    my $method = lc( $request->method );

    for ( @{ $self->_event_handlers->{ BEFORE_DISPATCH() } } ) {
        if ( !$_->( $self, $context ) ) {
            goto DONE;
        }
    }

    my $route =
      $self->handlers->get( $context->request->request_uri, $method, $context );
    if ( defined $route ) {
        $route->dispatch( $self, $context );
    }
    else {
        $context->status(405);
        $context->body('405 Method Not Supported');
        goto DONE;
    }

    $_->( $self, $context )
      for ( @{ $self->_event_handlers->{ AFTER_DISPATCH() } } );

  DONE:

    # HEAD requests only want headers.
    $context->body = [] if $method eq 'head';

    return $context->to_psgi;
}

sub BUILD {
    my $self = shift;

    $self->{_event_handlers} = { map { $_ => [] } EVENTS->@* };

    return $self;
}

sub middleware {
    my ( $self, @args ) = @_;

    push $self->middlewares->@*, [@args];

    return $self;
}

# Add a database or access an existing database:
#
# $slick->database('foo'); # Get's an existing database labeled 'foo'
#
# $slick->database(foo => 'postgresql://foo@bar:5432/mydb'); # Attempts to create a database labeled foo
sub database {
    my ( $self, $name, $conn ) = @_;

    if ( defined $conn ) {
        return $self->dbs->{$name} = Slick::Database->new( conn => $conn );
    }

    return $self->dbs->{$name};
}

# Runs the application with the server
sub run {
    my ( $self, %args ) = @_;

    my $server = $args{server} // 'HTTP::Server::PSGI';
    $self->{port} = $args{port} // 8000;
    $self->{addr} = $args{addr} // '127.0.0.1';

    require_module $server;

    if ( $self->env eq 'dev'
        || ( $self->env ne 'dev' && !$self->server ) )
    {
        $self->{server} = $server->new(
            host            => $self->addr,
            port            => $self->port,
            timeout         => $self->timeout,
            server_software => "Slick (Perl + PSGI) v$VERSION"
        );
    }

    say "\n" . $self->banner . "\n";

    my ( $addr, $port ) = ( $self->addr, $self->port );
    say "Slick is listening on: http://$addr:$port\n";

    return $self->server->run( $self->app );
}

# This is for users who want to use plackup
sub app {
    my $self = shift;

    return builder {
        enable 'Plack::Middleware::AccessLog' => format => 'combined';
        enable $_->@* for $self->middlewares->@*;
        sub { return $self->_dispatch(@_); }
    };
}

1;
