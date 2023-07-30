package Slick::Route;

use Moo;
use Types::Standard qw(CodeRef HashRef Str);
use Slick::Events   qw(EVENTS BEFORE_DISPATCH AFTER_DISPATCH);

with 'Slick::EventHandler';

has route => (
    is       => 'ro',
    isa      => Str,
    required => 1
);

has callback => (
    is       => 'ro',
    isa      => CodeRef,
    required => 1
);

sub dispatch {
    my ( $self, @args ) = @_;

    for ( @{ $self->_event_handlers->{ BEFORE_DISPATCH() } } ) {
        if ( !$_->(@args) ) {
            goto DONE;
        }
    }

    $self->callback->(@args);

    for ( @{ $self->_event_handlers->{ AFTER_DISPATCH() } } ) {
        if ( !$_->(@args) ) {
            goto DONE;
        }
    }

  DONE:

    return;
}

1;
