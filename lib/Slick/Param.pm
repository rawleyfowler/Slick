package Slick::Param;

use 5.036;

use Moo;
use Types::Standard qw(Str);

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1
);

1;
