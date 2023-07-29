package Slick::Util;

use 5.036;

sub four_digit_number {
    my @chars = ( 1 .. 9 );

    my $n = '';
    for ( 1 .. ( scalar @chars ) ) {
        $n .= $chars[ int rand @chars ];
    }

    return $n;
}

1;
