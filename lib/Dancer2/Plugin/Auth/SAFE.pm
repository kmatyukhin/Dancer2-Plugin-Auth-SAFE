package Dancer2::Plugin::Auth::SAFE;

use strict;
use warnings;

our $VERSION = '0.01';

use Dancer2::Plugin;
use MooX::Types::MooseLike::Base qw( Str );
use namespace::autoclean;

has safe_url => (
    is          => 'ro',
    isa         => Str,
    from_config => 1,
);

plugin_keywords qw( require_login logged_in_user );

sub BUILD {
    my ($plugin) = @_;

    return $plugin->app->add_route(
        method => 'post',
        regexp => '/safe',
        code   => \&_authenticate_user,
    );
}

sub require_login {
    my ( $plugin, $coderef ) = @_;

    return sub {
        my $firstname = $plugin->app->session->read('firstname');

        if ($firstname) {
            return $coderef->($firstname);
        }
        else {
            return $plugin->app->redirect( $plugin->safe_url );
        }
      }
}

sub logged_in_user {
    my ( $plugin, $coderef ) = @_;

    my $firstname = $plugin->app->session->read('firstname');

    return { firstname => $firstname };
}

sub _authenticate_user {
    my ($plugin) = @_;

    my $request   = $plugin->app->request;
    my $firstname = $request->params->{firstname};

    return $plugin->app->session->write( firstname => $firstname );
}

1;
