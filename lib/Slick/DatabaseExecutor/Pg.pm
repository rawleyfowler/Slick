package Slick::DatabaseExecutor::Pg;

use 5.036;

use Moo;
use SQL::Abstract;
use Carp qw(croak);

has sql => {
    is      => 'ro',
    isa     => 'SQL::Abstract',
    default => sub { SQL::Abstract->new; }
};

has connection => { is => 'ro' };

has dbi => { is => 'ro' };

sub BUILD {
    my $self = shift;

    my $db = split /\//x, $self->{connection}->path;

    my $dsn = defined $db ? "dbi:Pg:dbname=$db" : "dbi:Pg";
    if ( my $host = $self->{connection}->host ) { $dsn .= ";host=$host"; }
    if ( my $port = $self->{connection}->port ) { $dsn .= ";port=$port"; }

    my ( $username, $password ) =
      split /\:/x, [ split /\@/x, $self->{connection}->authority ]->[0];

    $self->{dbi} = DBI->connect(
        $dsn,
        $username // '',
        $password // '',
        { AutoCommit => 1 }
    );

    croak qq{Couldn't connect to database: } . $self->{connection}
      unless $self->dbi->ping;

    return $self;
}

1;
