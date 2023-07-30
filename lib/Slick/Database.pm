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

has type => (
    is  => 'ro',
    isa => Str
);

sub BUILD {
    my $self = shift;

    require_module('URI');

    my $uri = URI->new( $self->conn );

    if ( $uri->scheme =~ /^postgres(?:ql)?$/x ) {
        require_module('Slick::DatabaseExecutor::Pg');
        $self->{type} = 'Pg';
        $self->{dbh}  = Slick::DatabaseExecutor::Pg->new( connection => $uri );
    }
    elsif ( $uri->scheme =~ /^mysql$/x ) {
        require_module('Slick::DatabaseExecutor::MySQL');
        $self->{type} = 'mysql';
        $self->{dbh} =
          Slick::DatabaseExecutor::MySQL->new( connection => $uri );
    }
    else {
        croak qq{Unknown scheme or un-supported database: } . $uri->scheme;
    }

    return $self;
}

1;
