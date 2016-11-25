use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Response;
use Test::MockObject;
use lib 't/lib';

BEGIN {
    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'test';
}

# my $mock = Test::MockObject->new();

# $mock->set_isa('LWP::UserAgent');

# $mock->set_always(
#     'request',
#     HTTP::Response->new(
#         200, 'OK', [ 'Content-Type' => 'text/html; charset=UTF-8' ], '</>'
#     )
# );

# $mock->set_always( 'is_success', 1 );

{

    package TestApp;

    use Dancer2;
    use Dancer2::Plugin::Auth::SAFE;

    # set plugins => {
    #     'Auth::SAFE' => {
    #         ua => $mock,
    #     },
    # };

    get '/users' => require_login sub {
        my $user = logged_in_user;
        return "Hi there, $user->{username}";
    };
}

my $app = TestApp->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

my $res = $test->request( GET '/users' );

ok( $res->is_redirect, 'Redirect' );
is(
    $res->header('Location'),
    'https://safe.thomson.com/login/sso/SSOService?app=dcr-test',
    'Redirect location'
);

done_testing;
