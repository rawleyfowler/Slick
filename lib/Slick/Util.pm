package Slick::Util;

use 5.036;

use Sub::Util qw(set_subname);

# Generate a 4 digit number for request tracing
sub four_digit_number {
    my @chars = ( 1 .. 9 );

    my $n = '';
    for ( 1 .. 4 ) {
        $n .= $chars[ int rand @chars ];
    }

    return $n;
}

## no critic qw(TestingAndDebugging::ProhibitNoStrict TestingAndDebugging::ProhibitNoWarnings Subroutines::RequireFinalReturn)
sub monkey_patch {

# Credits to: https://github.com/mojolicious/mojo/blob/1343054b7f5c3e8c70c073e28c7ac65ab4008723/lib/Mojo/Util.pm#L200C1-L206C2

    my ( $class, %patch ) = @_;
    no strict 'refs';
    no warnings 'redefine';
    *{"${class}::$_"} = set_subname( "${class}::$_", $patch{$_} )
      for keys %patch;
}

1;
