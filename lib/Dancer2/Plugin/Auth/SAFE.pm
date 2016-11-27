package Dancer2::Plugin::Auth::SAFE;

use strict;
use warnings;

our $VERSION = '0.01';

use Dancer2::Plugin;
use Dancer2::Core::Types qw( Str );
use Digest::MD5 qw( md5_hex );
use HTTP::Status qw( :constants );
use DateTime;
use Const::Fast;
use namespace::autoclean;

const my $MAX_TIMESTAMP_DEVIANCE => 5;

has safe_url => (
    is          => 'ro',
    isa         => Str,
    from_config => 1,
);

has shared_secret => (
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
        code   => _authenticate_user($plugin),
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

    return sub {
        my ($self) = @_;

        my $params = $self->app->request->params;

        my ( $uid, $timestamp, $digest ) = @{$params}{qw( uid time digest )};

        if (
               defined $uid
            && defined $timestamp
            && defined $digest

            && $digest eq md5_hex( $uid . $timestamp . $plugin->shared_secret )
            && _timestamp_deviance($timestamp) < $MAX_TIMESTAMP_DEVIANCE
          )
        {
            my $firstname = $params->{firstname};

            return $self->app->session->write( firstname => $firstname );
        }
        else {
            return $self->app->send_error( 'Authentication error',
                HTTP_UNAUTHORIZED );
        }
      }
}

sub _timestamp_deviance {
    my ($timestamp) = @_;

    my %date_time;
    @date_time{qw( year month day hour minute second )} =
      split /:/xms, $timestamp;

    my $current_time = DateTime->now;
    my $digest_time  = DateTime->new(%date_time);

    return $current_time->delta_ms($digest_time)->{minutes};
}

1;
