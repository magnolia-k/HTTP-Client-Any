# NAME

HTTP::Client::Any - Generic HTTP client interface

# SYNOPSIS

    require HTTP::Client::Any;

    # http access
    my $http = HTTP::Client::Any->new;
    my $res_http = $http->get( 'http://www.example.com' );

    if ( $res_http->is_success ) {
        print $res_http->content;
    }

    # https access
    my $https = HTTP::Client::Any->new( https => 1 );
    my $res_https = $https->get( 'https://github.com' );

    if ( $res_https->is_success ) {
        print $res_https->content;
    }

    # mirror method
    my $mirror = HTTP::Client::Any->new;
    my $uri = 'http://www.cpan.org/src/5.0/perl-5.18.1.tar.gz';
    my $res_mirror = $mirror->mirror( $uri, 'perl-5.18.1.tar.gz' );

    if ( $res_mirror->is_success ) {
        ....
    }

# DESCRIPTION

HTTP::Client::Any is generic HTTP client interface module.

The priority of the client to be used is as follows. 

Furl -> LWP -> curl -> HTTP::Client

The client installed is chosen automatically. 

