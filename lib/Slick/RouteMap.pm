package Slick::RouteMap;

use 5.036;

use Moo;
use Types::Standard qw(HashRef);
use Slick::Methods  qw(METHODS);
use Carp            qw(croak);
use Scalar::Util    qw(blessed);
use List::Util      qw(first);

has _map => (
    is      => 'ro',
    isa     => HashRef,
    default => sub {
        return {
            '/' => {
                children => {},
                methods  => {}
            }
        };
    }
);

sub add {
    my ( $self, $route, $method ) = @_;

    croak qq{Unrecognized HTTP method $method.}
      unless defined( grep { $_ eq $method } METHODS() );

    chomp($route);
    my $uri =
        substr( $route->route, 0, 1 ) eq '/'
      ? substr( $route->route, 1 )
      : $route->route;

    my $m = $self->_map->{'/'};

    my @parts = split /\//x, $uri;
    if ( @parts && substr( $uri, -1 ) eq '/' ) {
        $parts[-1] .= '/';
    }

    for (@parts) {
        if ( exists $m->{children}->{$_} ) {
            $m = $m->{children}->{$_};
        }
        else {
            $m->{children}->{$_} = { children => {} };
            $m = $m->{children}->{$_};
        }
    }

    $m->{methods}->{$method} = $route;

    return $self;
}

## no critic qw(Subroutines::ProhibitExplicitReturnUndef)
sub get {
    my ( $self, $uri, $method, $context ) = @_;

    chomp($uri);

    return $self->_map->{'/'}->{methods}->{$method} if $uri eq '/';

    $uri =
        substr( $uri, 0, 1 ) eq '/'
      ? substr( $uri, 1 )
      : $uri;

    my $m = $self->_map->{'/'};

    my @parts = split /\//x, $uri;
    if ( @parts && substr( $uri, -1 ) eq '/' ) {
        $parts[-1] .= '/';
    }

    my $params = {};
    for (@parts) {
        if ( exists $m->{children}->{$_} ) {
            $m = $m->{children}->{$_};
            next;
        }

        my $param;
        my $part = $_;
        for ( keys %{ $m->{children} } ) {
            ($param) = /^\{([\w_]+)\}$/x;
            $param // next;
            $params->{$param} = $part;
            $m = $m->{children}->{"{$param}"};
            last;
        }

        return undef unless defined $param;
    }

    $context->{params} = $params;

    return $m->{methods}->{$method};
}

1;

=encoding utf8

=head1 NAME

Slick::RouteMap

=head1 SYNOPSIS

L<Slick::RouteMap> is a simple "Hash-Trie" that resolves routes extremely fast, at the cost of using slightly more
memory than other routing schemes.

=head1 API

=head2 get

Given a uri (Str), method (Str), and L<Slick::Context>, find the associated L<Slick::Route>, and return it.
Otherwise return C<undef>.

=head2 add

Given a L<Slick::Route> and a uri (Str), add it to the Hash-Trie for later lookup.

=head1 See also

=over2

=item * L<Slick>

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
