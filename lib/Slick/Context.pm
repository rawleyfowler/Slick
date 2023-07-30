package Slick::Context;

use Moo;
use Slick::Util;
use Types::Standard qw(Str HashRef);
use Module::Runtime qw(require_module);
use URI::Query;
use JSON::Tiny qw(encode_json);

# STATIC
sub REDIRECT { return 'R'; }
sub STANDARD { return 'S'; }

has id => (
    is      => 'ro',
    isa     => Str,
    default => sub { return Slick::Util->four_digit_number; }
);

has stash => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { return {}; }
);

has request => (
    is       => 'ro',
    isa      => HashRef,
    required => 1
);

has response => (
    is      => 'rw',
    isa     => HashRef,
    default => sub {
        return {
            status  => 200,
            body    => [''],
            headers => [ 'X-Server' => 'Slick (Perl + PSGI)' ]
        };
    }
);

has query => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { return {}; }
);

has param => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { return {}; }
);

has log => (
    is      => 'ro',
    default => sub {
        require_module('Log::Log4perl');
        return Log::Log4perl->get_logger('Slick');
    }
);

has _initiated_time => (
    is      => 'ro',
    default => sub { require_module('Time::HiRes'); return time; }
);

sub BUILD {
    my $self = shift;

    $self->{query} = URI::Query->new( $self->request->{QUERY_STRING} )->hash;

    return $self;
}

sub to_psgi {
    my $response = shift->response;
    return [ $response->{status}, $response->{headers}, $response->{body} ];
}

sub redirect {
    my ( $self, $location, $status ) = @_;

    $self->status( $status // 303 );
    $self->header( Location => $location );

    return $self;
}

sub header {
    my ( $self, $key, $value ) = @_;

    my %headers = @{ $self->response->{headers} };
    $headers{$key} = $value;
    $self->response->{headers} = [%headers];

    return $self;
}

sub status {
    my $self   = shift;
    my $status = shift;

    $self->response->{status} = $status;

    return $self;
}

sub json {
    my $self = shift;
    my $body = shift;

    require_module('JSON::Tiny');

    $self->header( 'Content-Type', 'application/json; encoding=utf8' );
    $self->body( encode_json $body);

    return $self;
}

sub text {
    my $self = shift;
    my $body = shift;

    $self->body($body);
    $self->header( 'Content-Type', 'text/plain' );

    return $self;
}

sub body {
    my $self = shift;
    my $body = shift;

    $self->response->{body} = [$body];

    return $self;
}

sub indexable_uri {
    my $self = shift;
    return
      lc( $self->request->{REQUEST_METHOD} ) . ':'
      . $self->request->{REQUEST_URI};
}

sub fmt {
    my $self = shift;

    return sprintf(
        '[%s] [%s] [%s] - %s',
        $self->request->{REMOTE_ADDR},
        $self->id,
        $self->request->{REQUEST_METHOD},
        $self->request->{REQUEST_URI}
          . (
            $self->request->{QUERY_STRING}
            ? '?' . $self->request->{QUERY_STRING}
            : ''
          )
    );
}

sub fmt_response {
    my $self = shift;

    return sprintf(
        '[%s] [%s] [%s] - %s - %s',
        $self->request->{REMOTE_ADDR},
        $self->id,
        $self->request->{REQUEST_METHOD},
        $self->request->{REQUEST_URI}
          . (
            $self->request->{QUERY_STRING}
            ? '?' . $self->request->{QUERY_STRING}
            : ''
          ),
        $self->response->{status}
    );
}

1;
