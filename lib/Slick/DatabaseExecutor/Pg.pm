package Slick::DatabaseExecutor::Pg;

use 5.036;

use Moo;
use Carp qw(croak);
use DBI;

with 'Slick::DatabaseExecutor';

sub BUILD {
    my $self = shift;

    my $db = ( split /\//x, $self->{connection}->path )[1];

    my $dsn = defined $db ? "dbi:Pg:dbname=$db" : "dbi:Pg";
    if ( my $host = $self->{connection}->host ) { $dsn .= ";host=$host"; }
    if ( my $port = $self->{connection}->port ) { $dsn .= ";port=$port"; }

    my ( $username, $password ) =
      split /\:/x, [ split /\@/x, $self->{connection}->authority ]->[0];

    $self->{dbi} = DBI->connect( $dsn, $username // '', $password // '',
        $self->dbi_options );

    croak qq{Couldn't connect to database: } . $self->{connection}
      unless $self->dbi->ping;

    return $self;
}

1;
