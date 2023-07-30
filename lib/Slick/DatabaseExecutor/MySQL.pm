package Slick::DatabaseExecutor::MySQL;

use 5.036;

use Moo;
use Carp qw(croak);

with 'Slick::DatabaseExecutor';

sub BUILD {
    my $self = shift;

    my $db = split /\//x, $self->{connection}->path;

    my $dsn = defined $db ? "dbi:mysql:dbname=$db" : "dbi:Pg";
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
