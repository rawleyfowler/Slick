package Slick::Context;

use Moo;
use Slick::Util;
use Types::Standard qw(Str HashRef);

has id => {
    is      => 'ro',
    isa     => Str,
    default => sub { return Slick::Util->four_digit_number; }
};

has stash => {
    is      => 'rw',
    isa     => HashRef,
    default => sub { return {}; }
};

has request => {
    is       => 'ro',
    isa      => HashRef,
    required => 1
};

has response => {
    is      => 'rw',
    isa     => HashRef,
    default => sub {
        return {
            status  => 200,
            body    => [''],
            headers => [ 'X-Server' => 'Slick (Perl + PSGI)' ]
        };
    }
};

sub REDIRECT { return 'R'; }
sub STANDARD { return 'S'; }

1;
