package Slick::Methods;

use 5.036;

use Exporter qw(import);

our @EXPORT_OK = qw(METHODS);

sub METHODS {
    return [qw(get post put patch delete head options)];
}

1;
