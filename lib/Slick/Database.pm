package Slick::Database;

use 5.036;

use Moo;
use Types::Standard qw(Str);
use Module::Runtime qw(require_module);
use Carp            qw(croak);

has conn => (
    is       => 'ro',
    isa      => Str,
    required => 1
);

has dbh => ( is => 'ro' );

sub BUILD {
    my $self = shift;

    require_module 'URI';

    my $uri = URI->new( $self->conn );

    if (   $uri->scheme eq 'postgresql'
        || $uri->scheme eq 'postgres' )
    {
        $self->{dbh} = Slick::Database::Pg->new($uri);
    }
    else {
        croak qq{Unknown scheme for connection: } . $uri->scheme;
    }

    return $self;
}

1;
