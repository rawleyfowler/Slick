package Slick::Context;

use 5.036;

use Moo;
use Slick::Util;
use Types::Standard qw(Str HashRef);
use Module::Runtime qw(require_module);
use URI::Query;
use URL::Encode;
use JSON::Tiny qw(encode_json decode_json);
use YAML::Tiny;

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

has _initiated_time => (
    is      => 'ro',
    default => sub { require_module('Time::HiRes'); return time; }
);

sub _decode_content {
    my $self = shift;

    state $known_types = {
        'application/json'                => sub { return decode_json(shift); },
        'text/json'                       => sub { return decode_json(shift); },
        'application/json; encoding=utf8' => sub { return decode_json(shift); },
        'application/yaml'   => sub { return YAML::Tiny->read_string(shift); },
        'text/yaml'          => sub { return YAML::Tiny->read_string(shift); },
        'application/x-yaml' => sub { return YAML::Tiny->read_string(shift); },
        'application/x-www-form-urlencoded' =>
          sub { return url_decode_utf8(shift); }
    };

    return $known_types->{ $self->request->content_type }
      ->( $self->request->content )
      if exists $known_types->{ $self->request->content_type };

    if ( rindex( $self->request->content_type, 'application/json', 0 ) == 0 ) {
        return decode_json( $self->request->content );
    }
    elsif (
        rindex( $self->request->content_type,
            'application/x-www-form-urlencoded' ) == 0
      )
    {
        return url_decode_utf8( $self->request->content );
    }
    elsif (rindex( $self->request->content_type, 'application/yaml', 0 ) == 0
        || rindex( $self->request->content_type, 'application/x-yaml', 0 ) ==
        0 )
    {
        return YAML::Tiny->read_string( $self->request->content );
    }
}

sub BUILD {
    my $self = shift;

    $self->{query} = URI::Query->new( $self->request->query_string )->hash;

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

sub content {
    my $self = shift;

    state $val = $self->_decode_content;

    return $val;
}

1;
