package Slick;

use 5.036;

use Moo;
use Types::Standard qw(HashRef ArrayRef Int Str);
use Module::Runtime qw(require_module);
use Carp            qw(croak);
use Tree::Trie;
use Slick::Context;

our $VERSION = '0.001';

has port => (
    is      => 'ro',
    lazy    => 1,
    isa     => Int,
    default => sub { return 8000; }
);

has events => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { return [ 'before_dispatch', 'after_dispatch' ]; }
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
    lazy    => 1,
    isa     => 'Tree::Trie',
    default => sub { return Tree::Trie->new; }
);

has _event_handlers => (
    is   => 'ro',
    lazy => 1,
    isa  => HashRef
);

sub _convert_context {
    my $self    = shift;
    my $context = shift;
}

sub _handle {
    my $self    = shift;
    my $request = shift;

    my $context = Slick::Context->new( request => $request );

    $context->log_request;

    for ( split //x, $request->{URI} ) {
        my (%routes) = $self->handlers->lookup_data($_);

        next if ( len( keys %routes ) > 1 );

        return [ '404', [], ['404 Not Found'] ] unless ( len( keys %routes ) );

        my $callback = ( values %routes )[0];

        for ( @{ $self->_event_handlers->{before_dispatch} } ) {
            if ( !$_->( $self, $context ) ) {
                goto DONE;
            }
        }

        $callback->( $self, $context );

        for ( @{ $self->_event_handlers->{after_dispatch} } ) {
            if ( !$_->( $self, $context ) ) {
                goto DONE;
            }
        }

        last;
    }

  DONE:
    $context->log_response;

    return $self->_convert_context($context);
}

sub BUILD {
    my $self = shift;
    require_module 'HTTP::Server::PSGI';

    if ( $self->env eq 'dev'
        || ( $self->env ne 'dev' && !$self->server ) )
    {
        $self->{server} = HTTP::Server::PSGI->new(
            host            => $self->config->addr,
            port            => $self->config->port,
            timeout         => $self->config->timeout,
            server_software => "Slick (Perl + PSGI) v$VERSION"
        );
    }

    $self->{_event_handlers} = { map { $_ => [] } @{ $self->events } };

    return $self;
}

# Add a database or access an existing database:
#
# $slick->database('foo'); # Get's an existing database labeled 'foo'
#
# $slick->database(foo => 'postgresql://foo@bar:5432/mydb'); # Attempts to create a database labeled foo
sub database {
    my ( $self, $name, $conn ) = @_;

    if ($conn) {
        return $self->dbs->{$name} = Slick::Database->new( conn => $conn );
    }

    return $self->dbs->{$name};
}

# Register an event (middleware)
sub on {
    my ( $self, $event, $code ) = @_;

    croak qq{Invalid type specified for event, expected CODE got } . ref($code)
      unless ( ref($code) eq 'CODE' );

    croak qq{Invalid event '$event', I only know of } . @{ $self->events }
      unless exists $self->_event_handlers->{$event};

    push @{ $self->_event_handlers->{$event} }, $code;
    return $code;
}

# Runs the application with the server
sub run {
    my $self   = shift;
    my $server = shift;
    return $self->server->run( sub { return $self->_handle(@_); } );
}

1;
