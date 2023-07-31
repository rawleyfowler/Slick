# Slick

Slick is an Object-Oriented Perl web-framework for building fast, and easy to refactor REST API's. 
Slick is built on top of [DBI](https://metacpan.org/pod/DBI), [Plack](https://metacpan.org/pod/Plack), 
and [Moo](https://metacpan.org/pod/Moo) and fits somewhere in-between the realms of Dancer and Mojo.

Slick has everything you need to build a Database driven REST API, including built in support
for Database connections, Migrations, and route based Caching (WIP). Since Slick is a Plack application,
you can also take advantage of swappable backends and Plack middlewares fairly simply.

## Examples

```perl
use 5.036;

use Slick;

my $s = Slick->new;

# Both MySQL and Postgres are supported databases
# Slick will create the correct DB object based on the connection URI
# [{mysql,postgres,postgresql}://][user[:[password]]@]host[:port][/schema]
$s->database(my_db => 'postgresql://user:password@127.0.0.1:5432/schema');
$s->database(corporate_db => 'mysql://corporate:secure_password@127.0.0.1:3306/schema');

$s->database('my_db')->migration(
	'create_user_table', # id
	'CREATE TABLE user ( id SERIAL PRIMARY KEY AUTOINCREMENT, name TEXT, age INT );', #up
	'DROP TABLE user;' # down
);

$s->database('my_db')->migrate_up; # Migrates all pending migrations

$s->get('/users/{id}' => sub {
	my $app = shift;
	my $context = shift;

	# Queries follow SQL::Abstract's notations
	my $user = $app->database('my_db')->select_one('user', { id => $context->param('id') });

	# Render the user hashref as JSON.
	$context->json($user);
});

$s->post('/users' => sub {
    my $app = shift;
    my $context = shift;
    
    my $new_user = $context->body; # Will be decoded from JSON, YAML, or URL encoded
    
    $app->database('my_db')->insert('user', $new_user);
    
    $context->json($new_user);
});

# Run the application on HTTP::Server::PSGI
$s->run;

# Alternatively run with a different server on a different port/address
$s->run(server => 'Gazelle', port => 9999, addr => '0.0.0.0');
```
