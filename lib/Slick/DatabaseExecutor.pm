package Slick::DatabaseExecutor;

use 5.036;

use Moo::Role;
use Carp qw(croak);
use SQL::Abstract;
use Scalar::Util qw(blessed);
use namespace::clean;

has sql => (
    is  => 'ro',
    isa => sub {
        my $s = shift;
        croak qq{Invalid type for sql, expected SQL::Abstract got } . $s
          unless blessed($s) eq 'SQL::Abstract';
    },
    default => sub { SQL::Abstract->new; }
);

has connection => ( is => 'ro' );

has dbi => ( is => 'ro' );

1;
