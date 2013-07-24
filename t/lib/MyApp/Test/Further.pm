package MyApp::Test::Further;

use strict;
use warnings;
use utf8;
use URI;

use JSON::XS;
use Catalyst::Test q(MyApp);

use HTTP::Request::Common qw(GET POST DELETE HEAD);
use Test::More;

# coloca use strict/warnings sozinho
sub import {
    strict->import;
    warnings->import;
}

# importa as funcoes para o script.
no strict 'refs';
*{"main::$_"} = *$_ for grep { defined &{$_} } keys %MyApp::Test::Further::;
use strict 'refs';

my $auth_user = 0;

our $stash = {};

our $list_urls = {};

sub api_auth_as {
    my (%conf) = @_;

    $conf{user_id} ||= 1;
    $conf{roles}   ||= ['superadmin'];

    unless ($auth_user) {
        require Package::Stash;
        require MyApp::TestOnly::Mock::AuthUser;

        my $stashc    = Package::Stash->new('Catalyst::Plugin::Authentication');
        my $auth_user = MyApp::TestOnly::Mock::AuthUser->new;

        $stashc->add_symbol( '&user',  sub { return $auth_user } );
        $stashc->add_symbol( '&_user', sub { return $auth_user } );
    }

    $MyApp::TestOnly::Mock::AuthUser::_id    = $conf{id};
    @MyApp::TestOnly::Mock::AuthUser::_roles = @{ $conf{roles} };
}

sub db_transaction (&) {
    my ($subref) = @_;

    my $schema = MyApp->model('DB');

    eval {
        $schema->txn_do(
            sub {
                $subref->($schema);
                die 'rollback';
            }
        );
    };

    die $@ unless $@ =~ /rollback/;

}

sub rest_put {
    my $url  = shift;
    my $data = pop;
    my %conf = @_;

    &rest_post( $url, code => ( exists $conf{is_fail} ? 400 : 202 ), method => 'PUT', %conf, $data );
}

sub rest_delete {
    my $url  = shift;
    my %conf = @_;

    &rest_post( $url, code => 204, method => 'DELETE', %conf, [] );
}

sub rest_post {
    my $url  = shift;
    my $data = pop;
    my %conf = @_;

    $conf{code} ||= exists $conf{is_fail} ? 400 : 201;

    my $name = $conf{name} || "POST $url";
    my $stashkey = exists $conf{stash} ? $conf{stash} : undef;

    my $req = POST $url, $data;

    $req->method( $conf{method} ) if exists $conf{method};

    my ( $res, $c ) = ctx_request($req);

    if ( exists $conf{is_fail} ) {
        if ( !ok( !$res->is_success, $name . ' is_fail' ) ) {
            eval('use Data::Printer; p $res');
        }
    }
    else {

        if ( !ok( $res->is_success, $name . ' is_success' ) ) {
            eval('use Data::Printer; p $res');
        }
    }
    is( $res->code, $conf{code}, $name . ' status code is ' . $conf{code} );

    return 'deleted!!' if $conf{code} == 204;

    if ( exists $conf{is_fail} ) {
        return undef if $res->is_success;
    }
    else {
        return undef unless $res->is_success;
    }

    my $obj = eval { decode_json( $res->content ) };
    fail($@) if $@;

    if ( $conf{code} == 201 ) {
        like( $obj->{id}, qr/^[0-9]+$/, 'id ' . $obj->{id} . ' looks int' );

        $stash->{ $stashkey . '.id' } = $obj->{id} if $stashkey;
    }

    my $item_url = $res->header('Location');

    if ($stashkey) {
        $stash->{$stashkey} = $obj;
        $stash->{ $stashkey . '.url' } = $item_url;
    }

    if ( $stashkey && $conf{code} == 201 ) {

        &rest_reload($stashkey);
    }

    if ( $stashkey && exists $conf{list} ) {

        my ( $res, $c ) = ctx_request( GET $url );
        ok( $res->is_success, 'GET ' . $url . ' is_success' );
        is( $res->code, 200, 'GET ' . $url . ' status code is 200' );

        my $obj3 = eval { decode_json( $res->content ) };
        fail($@) if $@;

        $stash->{ $stashkey . '.list' } = $obj3;

        $list_urls->{$stashkey} = $url;
    }

    return $obj;
}

sub rest_reload {
    my ( $stashkey, $exp_code ) = @_;

    $exp_code ||= 200;

    my $item_url = $stash->{ $stashkey . '.url' };

    my ( $res, $c ) = ctx_request( GET $item_url );

    if ( $exp_code == 200 ) {
        if ( !ok( $res->is_success, 'GET ' . $item_url . ' is_success' ) ) {
            eval('use Data::Printer; p $res');
        }
        is( $res->code, 200, 'GET ' . $item_url . ' status code is 200' );

        my $obj = eval { decode_json( $res->content ) };
        fail($@) if $@;

        $stash->{ $stashkey . '.get' } = $obj;
    }
    elsif ( $exp_code == 404 ) {

        ok( !$res->is_success, 'GET ' . $item_url . ' does not exists' );
        is( $res->code, 404, 'GET ' . $item_url . ' status code is 404' );

        delete $stash->{ $stashkey . '.get' };
        delete $stash->{ $stashkey . '.id' };
        delete $stash->{ $stashkey . '.url' };
        delete $stash->{ $stashkey . '.list' };
        delete $stash->{$stashkey};

    }
    else {
        die "not supported $exp_code code!";
    }

    return $res;
}


sub rest_get {
    my ( $url, $exp_code, $params ) = @_;

    $params ||= {};

    my $uri = URI->new( $url );
    $uri->query_form( %$params );
    $url = $uri->as_string;

    $exp_code ||= 200;

    my ( $res, $c ) = ctx_request( GET $url );

    if ( $exp_code == 200 ) {
        ok( $res->is_success, 'GET ' . $url . ' is_success' );
        is( $res->code, 200, 'GET ' . $url . ' status code is 200' );
    }
    else {
        is( $res->code, $exp_code, 'GET ' . $url . ' status code is ' . $exp_code );
    }

    my $obj = eval { decode_json( $res->content ) };
    fail($@) if $@;

    return $obj;
}

sub stash_test($&) {
    my ( $staname, $sub ) = @_;

    $sub->( $stash->{$staname} );
}

sub stash ($) {
    my ($key) = @_;
    return $stash->{$key};
}

sub rest_reload_list {
    my ($key) = @_;
    my $list = rest_get $list_urls->{$key};

    $stash->{ $key . '.list' } = $list;
    return $list;
}

1;
