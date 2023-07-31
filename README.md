# Slick

Slick is an Object-Oriented Perl web-framework for building fast, and easy to refactor REST API's. 
Slick is built on top of [DBI](https://metacpan.org/pod/DBI), [Plack](https://metacpan.org/pod/Plack), 
and [Moo](https://metacpan.org/pod/Moo) and fits somewhere in-between the realms of Dancer and Mojo.

Slick has everything you need to build a Database driven REST API, including built in support
for Database connections, Migrations, and route based Caching (WIP). Since Slick is a Plack application,
you can also take advantage of swappable backends and Plack middlewares fairly simply.

Currently, Slick supports `MySQL` and `Postgres` but there are plans to implement `Oracle` and `SQL Server`.

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

$s->run; # Run the application.
```

## Running with Rackup

If you wish to use `rackup` you can change the final call to `run` to a call to `app`

```perl
$s->app;
```

Then simply run with rackup (substitue `my_app.psgi` with whatever your app is called):

```bash
rackup -a my_app.psgi
```

## Changing PSGI backend

Will run on the default [`HTTP::Server::PSGI`](https://metacpan.org/pod/HTTP::Server::PSGI).
```perl
$s->run;
```

or 

In this example, running Slick with a [`Gazelle`](https://metacpan.org/pod/Gazelle) backend on port `8888` and address `0.0.0.0`.
```perl
$s->run(server => 'Gazelle', port => 8888, addr => '0.0.0.0'); 
```

## Using Plack Middlewares

You can register more Plack middlewares with your application very easily!

```perl
my $s = Slick->new;

$s->middleware('Deflater')
  ->middleware('Session' => store => 'file')
  ->middleware('Debug', panels => [ qw(DBITrace Memory) ]);

$s->run; # or $s->app depending on if you want to use plackup.
```

## Managing Your Database(s)

Slick allows you to easily connect databases to your applications.

### Creating a database
```perl
my $s = Slick->new;
$s->database(my_postgres => 'postgresql://username:password@127.0.0.1:5432/db_name');
```

### Migrations

Migrations are built using the `migration` method on `Slick::Database`. You provide 1, an ID for the migration,
2, the runnable/happy side of the migrations, and 3, the down or reverse of the migration.

```perl
$s->database('my_postgres')
  ->migration('create_users_table',
  'CREATE TABLE users ( id INT PRIMARY KEY, name TEXT, age INT );',
  'DROP TABLE user;')
  ->migration('create_pets_table',
  'CREATE TABLE pets ( id INT PRIMARY KEY, name TEXT, owner INT FOREIGN KEY REFERENCES users (id) );',
  'DROP TABLE pets;');
```

## Deployment

Please follow a standard `Plack` application deployment. Reverse-proxying your application behind
[`NGiNX`](https://nginx.org) or [`Caddy`](https://caddyserver.com) and using [`Docker`](https://www.docker.com) can
drastically improve your deployment.

An example `Dockerfile` can be found in the examples directory.

## Contributing

Slick is open to any and all contributions.

**Code Standards**:

* Always format with the provided `.perltidyrc`
* Always use `Perl::Critic` set to severity `3`
* Unpack subroutine arguments using array-destructuring when there are greater than 2 arguments

## License

Slick is provided under the Artistic 2.0 license.
