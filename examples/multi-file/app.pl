use 5.036;
use lib 'lib';

use Slick;
use MyApp::ItemRouter;

my $slick = Slick->new;

$slick->helper( item_validator => sub { return exists shift->{name} } );
$slick->database( items_db => 'sqlite://db.db' );

$slick->register( MyApp::ItemRouter->router );

$slick->run;
