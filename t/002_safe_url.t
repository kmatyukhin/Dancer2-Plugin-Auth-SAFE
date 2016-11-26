use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

BEGIN {
    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'safe_url';
}

{

    package TestApp;

    use Dancer2;
    use Dancer2::Plugin::Auth::SAFE;

    get '/' => require_login sub { };
}

my $app = TestApp->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

{
    my $res = $test->request( GET '/' );

    ok( $res->is_redirect, 'Redirect' );
    is(
        $res->header('Location'),
        'http://--- Put SAFE redirect URL here ---',
        'Redirect location'
    );
}

done_testing;
