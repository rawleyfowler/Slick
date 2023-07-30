package Slick::Logger;

use Moo;

has chan => (
    is      => 'ro',
    default => sub { return \*STDERR }
);

# Default Format: [REMOTE_IP] [CONTEXT_ID] [DATE] - [LOG MESSAGE]
has format => (
    is      => 'rw',
    default => sub { return '[%s] [%d] [%s] - [%s]'; }
);

1;
