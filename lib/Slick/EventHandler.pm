package Slick::EventHandler;

use 5.036;

use Moo::Role;
use Types::Standard qw(HashRef);
use Carp            qw(croak);
use Slick::Events   qw(EVENTS);
use List::Util      qw(reduce);

has _event_handlers => (
    is      => 'ro',
    lazy    => 1,
    isa     => HashRef,
    default => sub {
        my $r;
        @$r{ @{ EVENTS() } } = map { [] } EVENTS->@*;
        return $r;
    }
);

# Register an event (middleware)
sub on {
    my ( $self, $event, $code ) = @_;

    croak qq{Invalid type specified for event, expected CODE got } . ref($code)
      unless ( ref($code) eq 'CODE' );

    croak qq{Invalid event '$event', I only know of ( }
      . ( reduce { $a . ', ' . $b } EVENTS->@* ) . ' )'
      unless exists $self->_event_handlers->{$event};

    push @{ $self->_event_handlers->{$event} }, $code;
    return $code;
}

1;
