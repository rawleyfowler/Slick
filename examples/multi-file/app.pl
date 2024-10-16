use 5.036;
use lib 'lib';

use Slick;
use MyApp::ItemRouter;

my $slick = Slick->new;

$slick->helper( item_validator => sub { return exists shift->{name} } );
$slick->database( items_db => 'sqlite://db.db', auto_migrate => 1 );
$slick->items_db->migration(
    'create_items_table',
    'CREATE TABLE items ( id INT, name TEXT )',
    'DROP TABLE items'
);
$slick->items_db->migrate_up;

$slick->register( MyApp::ItemRouter->router );

$slick->run;
