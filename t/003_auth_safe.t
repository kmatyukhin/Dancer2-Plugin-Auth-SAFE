use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;
use Test::MockObject;

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
        return "Hi there, $user->{firstname}";
    };
}

my $app = TestApp->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);
my $url  = 'http://localhost';
my $jar  = HTTP::Cookies->new();

{
    my $res = $test->request( GET "$url/users" );
    ok( $res->is_redirect, 'Got redirect response' );
    $jar->extract_cookies($res);
    is(
        $res->header('Location'),
        'https://safe.thomson.com/login/sso/SSOService?app=dcr-test',
        'Redirect location is OK'
    );
}
{
    my $req = POST "$url/safe",
      [
        uid       => '0123456',
        firstname => 'John',
        lastname  => 'Doe',
        time      => '2016:11:26:17:48:40',
        digest    => '02c5f46a6bc822d1d1d7557269526f1e',
      ];
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    ok( $res->is_success, 'POST /safe response is OK' );
}
{
    my $req = GET "$url/users";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    ok( !$res->is_redirect, 'Got normal response' );
    is( $res->content, 'Hi there, John', 'User authenticated' );
}

done_testing;
