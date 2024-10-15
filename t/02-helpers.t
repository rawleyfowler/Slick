use Test::More;

use strict;
use warnings;

use Slick;

my $slick = Slick->new;

ok $slick->helper( test     => 'abc' ),       'non-sub helper ok?';
ok $slick->helper( test_two => sub { 123 } ), 'sub helper ok?';

is $slick->test(),     'abc', 'non-sub returns proper value?';
is $slick->test_two(), 123,   'sub returns proper value?';

is ref( $slick->helper('test') ),     'CODE', 'raw value correct type?';
is ref( $slick->helper('test_two') ), 'CODE', 'sub value correct type?';

done_testing;
