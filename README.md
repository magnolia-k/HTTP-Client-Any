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

# DESCRIPTION

HTTP::Client::Any is generic HTTP client interface module.
