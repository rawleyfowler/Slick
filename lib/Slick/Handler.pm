package Slick::Handler;

use 5.036;

use Moo;
use Types::Standard qw(Str CodeRef);

has route => {
    is       => 'ro',
    isa      => Str,
    required => 1
};

has callback => {
    is       => 'ro',
    isa      => CodeRef,
    required => 1
};

1;
