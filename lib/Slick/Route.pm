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

=encoding utf8

=head1 NAME

Slick::Route

=head1 SYNOPSIS

An OO wrapper around a central callback and the route path itself.

Inherits from L<Slick::EventHandler>.

=head1 API

=head2 route

Returns the route at which this L<Slick::Route> is responsible for.

=head2 callback

Returns a C<CodeRef> to the callback that will be called with the route is hit.

=head2 dispatch

Dispatches a L<Slick> and a L<Slick::Context> against all local events and the callback.

=head1 See also

=over2

=item * L<Slick::Context>

=item * L<Slick::Database>

=item * L<Slick::DatabaseExecutor>

=item * L<Slick::DatabaseExecutor::MySQL>

=item * L<Slick::DatabaseExecutor::Pg>

=item * L<Slick::EventHandler>

=item * L<Slick::Events>

=item * L<Slick::Methods>

=item * L<Slick::RouteMap>

=item * L<Slick::Util>

=back

=cut
