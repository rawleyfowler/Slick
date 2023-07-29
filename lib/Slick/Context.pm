package Slick::Context;

use Moo;
use Slick::Util;
use Types::Standard qw(Str HashRef);
use Module::Runtime qw(require_module);
use URI::Query;

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
    is  => 'ro',
    isa => HashRef
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
    return [ values( %{ shift->response } ) ];
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

    my %headers = %{ $self->response->{headers} };
    $headers{'Content-Type'} = 'application/json; encoding=utf8';
    $self->response->{headers} = [%headers];

    $self->response->body = [ encode_json($body) ];

    return $self;
}

sub body {
    my $self = shift;
    my $body = shift;

    $self->response->body = [$body];

    return $self;
}

1;
