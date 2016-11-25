package Dancer2::Plugin::Auth::SAFE;

use strict;
use warnings;

our $VERSION = '0.01';

use Dancer2::Plugin;
use MooX::Types::MooseLike::Base qw( Str InstanceOf );
use namespace::autoclean;

has ua => (
    is          => 'ro',
    isa         => InstanceOf ['LWP::UserAgent'],
    from_config => sub {
        LWP::UserAgent->new();
    },
);

has safe_url => (
    is          => 'ro',
    isa         => Str,
    from_config => 1,
);

plugin_keywords qw/ require_login logged_in_user /;

sub require_login {
    my ( $plugin, $coderef ) = @_;

    return sub {
        $plugin->app->redirect( $plugin->safe_url );
      }
}

sub logged_in_user {
    my ( $plugin, $coderef ) = @_;

    return { username => 'bob' };
}

1;
