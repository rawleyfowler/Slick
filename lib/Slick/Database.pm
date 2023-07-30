package Slick::Database;

use 5.036;

use Moo;
use Types::Standard qw(Str HashRef);
use Module::Runtime qw(require_module);
use Carp            qw(croak);
use Try::Tiny;

my $first_migration = {
    up => <<'EOF',
CREATE TABLE IF NOT EXISTS slick_migrations (
  id VARCHAR(255) PRIMARY KEY,
  up TEXT,
  down TEXT
);
EOF
    down => <<'EOF'
DROP TABLE slick_migrations;
EOF
};

has conn => (
    is       => 'ro',
    isa      => Str,
    required => 1
);

has type => (
    is  => 'ro',
    isa => Str
);

has auto_migrate => (
    is      => 'rw',
    default => sub { return 0; }
);

has migrations => (
    is      => 'ro',
    default => sub {
        return { 'create_slick_migrations_table' => $first_migration };
    }
);

has _executor => (
    is      => 'ro',
    handles => [qw(insert update delete select execute dbi)]
);

sub BUILD {
    my $self = shift;

    require_module('URI');

    my $uri = URI->new( $self->conn );

    if ( $uri->scheme =~ /^postgres(?:ql)?$/x ) {
        require_module('Slick::DatabaseExecutor::Pg');
        $self->{type} = 'Pg';
        $self->{_executor} =
          Slick::DatabaseExecutor::Pg->new( connection => $uri );
    }
    elsif ( $uri->scheme =~ /^mysql$/x ) {
        require_module('Slick::DatabaseExecutor::MySQL');
        $self->{type} = 'mysql';
        $self->{_executor} =
          Slick::DatabaseExecutor::MySQL->new( connection => $uri );
    }
    else {
        croak q{Unknown scheme or un-supported database: } . $uri->scheme;
    }

    try {
        $self->dbi->do( $first_migration->{up} );
        $self->insert(
            'slick_migrations',
            {
                id   => 'create_slick_migrations_table',
                up   => $first_migration->{up},
                down => $first_migration->{down}
            }
        );
    }

    return $self;
}

sub migrate_up {
    my $self = shift;
    my $id   = shift;

    my $run_migrations = $self->select( 'slick_migrations', ['id'] );

    if ($id) {
        croak qq{Couldn't find migration: $id}
          unless exists $self->migrations->{$id};

        if ( not( grep { $_->{id} eq $id } $run_migrations->@* ) ) {
            my $migration = $self->migrations->{$id};
            $self->dbi->do( $migration->{up} )
              || croak qq{Couldn't migrate up $id - } . $self->dbi->errstr;

            $self->insert(
                'slick_migrations',
                {
                    id   => $id,
                    up   => $migration->{up},
                    down => $migration->{down}
                }
            );

            say qq{Migrated $id up successfully.};
        }
    }
    else {
        for ( keys $self->migrations->%* ) {
            my $key = $_;
            next
              if grep { $_->{id} eq $key } $run_migrations->@*;

            $self->dbi->do( $self->migration->{$_}->{up} )
              || croak qq{Couldn't migrate up $_ - } . $self->dbi->errstr;
            $self->insert(
                'slick_migrations',
                {
                    id   => $key,
                    up   => $_->{up},
                    down => $_->{down}
                }
            );

            say qq{Migrated $_ up successfully.};
        }
    }

    return $self;
}

sub migrate_down {
    my $self = shift;
    my $id   = shift;

    my $run_migrations = $self->select( 'slick_migrations', ['id'] );

    if ($id) {
        croak qq{Couldn't find migration: $id}
          unless exists $self->migrations->{$id};

        if ( not( grep { $_->{id} eq $id } $run_migrations->@* ) ) {
            my $migration = $self->migrations->{$id};
            $self->dbi->do( $migration->{down} )
              || croak qq{Couldn't migrate down $id - } . $self->dbi->errstr;
            $self->delete( 'slick_migrations', { id => $id } );

            say qq{Migrated $id down successfully.};
        }
    }
    else {
        for ( keys $self->migrations->%* ) {
            my $key = $_;
            next
              if grep { $_->{id} eq $key } $run_migrations->@*;

            $self->dbi->do( $self->migration->{$_}->{down} )
              || croak qq{Couldn't migrate down $_ - } . $self->dbi->errstr;
            $self->delete( 'slick_migrations', { id => $key } );

            say qq{Migrated $_ down successfully.};
        }
    }

    return $self;
}

sub migration {
    my ( $self, $id, $up, $down ) = @_;

    my $migration = {
        up   => $up,
        down => $down
    };

    $self->migrations->{$id} = $migration;

    if ( $self->auto_migrate ) {
        $self->migrate_up($id);
    }

    return $self;
}

1;
