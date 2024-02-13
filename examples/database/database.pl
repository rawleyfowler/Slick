use 5.036;

use Slick;

my $s = Slick->new;

# Both MySQL and Postgres are supported databases
# Slick will create the correct DB object based on the connection URI
# [{mysql,postgres,postgresql}://][user[:[password]]@]host[:port][/schema]
$s->database( my_db => 'postgresql://user:password@127.0.0.1:5432/schema' );
$s->database(
    corporate_db => 'mysql://corporate:secure_password@127.0.0.1:3306/schema' );

$s->database('my_db')->migration(
    'create_user_table',    # id
'CREATE TABLE user ( id SERIAL PRIMARY KEY AUTOINCREMENT, name TEXT, age INT );'
    ,                       #up
    'DROP TABLE user;'      # down
);

$s->database('my_db')->migrate_up;    # Migrates all pending migrations

$s->get(
    '/users/{id}' => sub {
        my $app     = shift;
        my $context = shift;

        # Queries follow SQL::Abstract's notations
        my $user = $app->database('my_db')
          ->select_one( 'user', { id => $context->param('id') } );

        # Render the user hashref as JSON.
        $context->json($user);
    }
);

$s->post(
    '/users' => sub {
        my $app     = shift;
        my $context = shift;

        my $new_user = $context->content
          ; # Will be decoded from JSON, YAML, or URL encoded (See JSON::Tiny, YAML::Tiny, and URL::Encode)

        $app->database('my_db')->insert( 'user', $new_user );

        $context->json($new_user);
    }
);

$s->run;    # Run the application.
