use 5.036;

use Slick;

my $s = Slick->new;

# See Redis and Cache::Memcached on CPAN for arguments

# Create a Redis instance
$s->cache(
    my_redis => type => 'redis',    # Slick Arguments
    server   => '127.0.0.1:6379'    # Cache::Memcached arguments
);

# Create a Memcached instance
$s->cache(
    my_memcached => type          => 'memcached',   # Slick Arguments
    servers      => ['127.0.0.1'] => debug => 1     # Cache::Memcached arguments
);

$s->cache('my_redis')->set( something => 'awesome' );

$s->get(
    '/foo' => sub {
        my ( $app, $context ) = @_;
        my $value = $app->cache('my_redis')->get('something');  # Use your cache
        return $context->text($value);
    }
);

$s->run;
