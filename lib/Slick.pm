package Slick;

use 5.036;

use Moo;
use Types::Standard qw(HashRef ArrayRef Int Str);
use Module::Runtime qw(require_module);
use Carp            qw(croak);
use Tree::Trie;
use Try::Tiny;
use Slick::Context;
use Slick::Events qw(EVENTS BEFORE_DISPATCH AFTER_DISPATCH);
use DDP;

our $VERSION = '0.001';

extends 'Slick::EventHandler';

foreach my $meth (qw(get post put patch delete)) {
    require_module('Slick::Util');
    require_module('Slick::Route');
    Slick::Util::monkey_patch(
        __PACKAGE__,
        $meth => sub {
            my ( $self, $route, $callback, $events ) = @_;

            my $route_object = Slick::Route->new(
                callback => $callback,
                route    => $route
            );

            if ($events) {
                foreach my $event ( @{ EVENTS() } ) {
                    $route_object->on( $event, $_ )
                      for ( @{ $events->{$event} } );
                }
            }

            $self->handlers->add_data( "$meth:$route" => $route_object );

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
    default => sub { return Tree::Trie->new; }
);

sub _dispatch {
    my $self    = shift;
    my $request = shift;

    my $context = Slick::Context->new( request => $request );

    # TODO: Logging
    # $self->logger->log_request($context);

    p $context;
    p $self;
    p $context->indexable_uri;
    p $self->handlers;

    for ( @{ $self->_event_handlers->{ BEFORE_DISPATCH() } } ) {
        if ( !$_->( $self, $context ) ) {
            goto DONE;
        }
    }

    for ( split //, $context->indexable_uri ) {
        my (%routes) = $self->handlers->lookup_data($_);

        p %routes;

        return [ '404', [], ['404 Not Found'] ]
          unless ( scalar( keys %routes ) );

        my $route = ( values %routes )[0];

        p $_;

        $route->dispatch( $self, $context );

        last;
    }

    $_->( $self, $context )
      for ( @{ $self->_event_handlers->{ AFTER_DISPATCH() } } );

  DONE:

    $context->body = [] if $context->request->{REQUEST_METHOD} eq 'HEAD';

    # TODO: Logging
    # $context->log_response;

    return $context->to_psgi;
}

sub BUILD {
    my $self = shift;
    require_module 'HTTP::Server::PSGI';

    if ( $self->env eq 'dev'
        || ( $self->env ne 'dev' && !$self->server ) )
    {
        $self->{server} = HTTP::Server::PSGI->new(
            host            => $self->addr,
            port            => $self->port,
            timeout         => $self->timeout,
            server_software => "Slick (Perl + PSGI) v$VERSION"
        );
    }

    $self->{_event_handlers} = { map { $_ => [] } @{ EVENTS() } };

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
    my $self   = shift;
    my $server = shift;
    return $self->server->run( sub { return $self->_dispatch(@_); } );
}

1;
