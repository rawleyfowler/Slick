package Slick::DatabaseExecutor;

use 5.036;

use Moo::Role;
use Types::Standard qw(HashRef);
use Carp            qw(croak);
use SQL::Abstract;
use Scalar::Util qw(blessed);
use Slick::Util;
use namespace::clean;

foreach my $sql_verb (qw(insert update delete)) {
    Slick::Util::monkey_patch(
        __PACKAGE__,
        $sql_verb,
        sub {
            my ( $self, @args ) = @_;
            my ( $stmt, @bind ) = $self->sql->$sql_verb(@args);
            my $sth = $self->prepare($stmt);
            return $sth->execute(@bind);
        }
    );

}

has sql => (
    is  => 'ro',
    isa => sub {
        my $s = shift;
        croak qq{Invalid type for sql, expected SQL::Abstract got } . $s
          unless blessed($s) eq 'SQL::Abstract';
    },
    default => sub { SQL::Abstract->new; }
);

has dbi => ( is => 'ro', handles => [ 'do', 'prepare' ] );

has connection => ( is => 'ro' );

has dbi_options => (
    is      => 'rw',
    isa     => HashRef,
    default => sub {
        return {
            AutoCommit => 1,
            PrintError => 1,
            RaiseError => 0
        };
    }
);

## no critic qw(Subroutines::ProhibitBuiltinHomonyms)
sub select {
    my ( $self, @args ) = @_;
    my ( $stmt, @bind ) = $self->sql->select(@args);
    my $sth = $self->prepare( $stmt, @bind );
    $sth->execute(@bind);
    return $sth->fetchall_arrayref( {} );
}

## no critic qw(Subroutines::ProhibitExplicitReturnUndef)
sub select_one {
    my ( $self, @args ) = @_;
    my $ar = $self->select(@args);

    if ( $ar->@* ) {
        return $ar->[0];
    }

    return undef;
}

1;
