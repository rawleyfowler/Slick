package Slick::DatabaseExecutor::SQLite;

use strict;
use warnings;

use Moo;
use Carp qw(croak);
use DBI;

with 'Slick::DatabaseExecutor';

sub BUILD {
    my $self = shift;

    my $db  = $self->{connection};
    my $dsn = "db:SQLite:dbname=$db";

    $self->{dbi} = DBI->connect( $dsn, '', '' );

    return $self;
}

1;

=encoding utf8

=head1 NAME

Slick::DatabaseExecutor::SQLite

=head1 SYNOPSIS

A child class of L<Slick::DatabaseExecutor>, handles all interactions with SQLite, mostly just configuring the connection.

=head1 See also

=over 2

=item * L<Slick>

=item * L<Slick::RouteManager>

=item * L<Slick::Context>

=item * L<Slick::Database>

=item * L<Slick::DatabaseExecutor>

=item * L<Slick::DatabaseExecutor::MySQL>

=item * L<Slick::EventHandler>

=item * L<Slick::Events>

=item * L<Slick::Methods>

=item * L<Slick::RouteMap>

=item * L<Slick::Util>

=back

=cut
