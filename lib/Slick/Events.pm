package Slick::Events;

use 5.036;

use Exporter qw(import);

our @EXPORT_OK = qw(BEFORE_DISPATCH AFTER_DISPATCH EVENTS);

sub BEFORE_DISPATCH { return 'before_dispatch'; }
sub AFTER_DISPATCH  { return 'after_dispatch'; }
sub EVENTS          { return [ BEFORE_DISPATCH(), AFTER_DISPATCH() ]; }

1;
