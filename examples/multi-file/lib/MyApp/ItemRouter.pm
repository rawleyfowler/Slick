package MyApp::ItemRouter;

use strict;
use warnings;

use Moo;

extends 'Slick::Router';

my $router = __PACKAGE__->new( base => '/items' );

$router->get(
    '/{id}' => sub {
        my ( $app, $context ) = @_;
        my $item =
          $app->items_db->select_one( 'items',
            { id => $context->param('id') } );
        $context->json($item);
    }
);

$router->post(
    '' => sub {
        my ( $app, $context ) = @_;
        my $new_item = $context->content;

        if ( not $app->item_validator->($new_item) ) {
            $context->status(400)->json( { error => 'Bad Request' } );
        }
        else {
            $app->items_db->insert( 'items', $new_item );
            $context->json($new_item);
        }
    }
);

sub router {
    return $router;
}

1;
