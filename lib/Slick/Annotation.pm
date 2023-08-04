package Slick::Annotation;

use 5.036;

use Exporter     qw(import);
use Carp         qw(carp);
use JSON::Tiny   qw(decode_json encode_json);
use Scalar::Util qw(blessed);

our @EXPORT_OK = qw(cacheable);

sub cacheable {
    my $cache   = shift;
    my $code    = shift;
    my $timeout = shift // 300;    # Default cache is 5 minutes

    return sub {
        my ( $app, $context ) = @_;

        state $cache_obj = $app->cache($cache);

        if ($cache_obj) {
            if ( $cache_obj->get( $context->request->uri ) ) {
                my $response =
                  decode_json( $cache_obj->get( $context->request->uri ) );

                $context->from_psgi($response);
            }
            else {
                $code->( $app, $context );

                my $json = encode_json $context->to_psgi;

                if ( blessed( $cache_obj->{_executor} ) =~ /Memcached/x ) {
                    $cache_obj->set(
                        $context->request->uri => $json => $timeout );
                }
                else {
                    $cache_obj->set(
                        $context->request->uri => $json => EX => $timeout );
                }
            }
        }
        else {
            carp
qq{Attempted to use cache $cache to cache route but cache does not exist.};
            $code->( $app, $context );
        }
    }
}

1;
