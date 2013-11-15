package HTTP::Client::Any;

use strict;
use warnings;

our $VERSION = 'v0.0.1';

use Module::Load::Conditional qw/check_install/;
use IPC::Cmd qw/can_run run/;
use File::Temp;
use Carp;

our $HTTP_CLIENTS = {

    'Furl'      =>  {
        id      => 'furl',
        type    => 'module',
        module  => 'Furl',
        https   => [ 'IO::Socket::SSL' ],
    },

    'LWP'       =>  {
        id      => 'lwp',
        type    => 'module',
        module  => 'LWP::UserAgent',
        https   => [ 'LWP::Protocol::https', 'Mozilla::CA' ],
    },

    'curl'      =>  {
        id      => 'curl',
        type    => 'command',
        command => 'curl',
    },

    'HTTP::Tiny'    => {
        id      => 'tiny',
        type    => 'module',
        module  => 'HTTP::Tiny',
        https   => [ 'IO::Socket::SSL' ],
    },
};

our $env;

__check_env();

sub new {
    my $class = shift;

    my $self = {
        client  =>  undef,
        notuse  =>  [],
        https   =>  undef,
        agent   =>  undef,
        @_,
    };

    bless $self, $class;

    $self->{client} ? $self->_validate_client : $self->_determine_client;

    return $self;
}

sub _validate_client {
    my $self = shift;

    my $client = $self->{client};

    if ( ! grep { $_ eq $client } keys %{ $HTTP_CLIENTS } ) {
        croak "Invalid HTTP Client:$client.";
    }

    if ( ! $env->{$client}{available} ) {
        croak "$client isn't installed.";
    }
    
    if ( $self->{https} ) {
        if ( ! $env->{$client}{https_ok} ) {
            croak "@{$HTTP_CLIENTS->{$client}{https}} is (are) required " .
                "for https access.";
        }
    }

    my $method = '_setup_' . $HTTP_CLIENTS->{$client}{id};

    $self->$method;
}

sub _determine_client {
    my $self = shift;

    if ( $env->{'Furl'}{available} and ( ! $self->{https} ) or $env->{'Furl'}{https_ok} ) {

        $self->{client} = 'Furl';
        $self->_setup_furl;

    } elsif ( $env->{"LWP"} and ( ( ! $self->{https} ) or  $env->{'LWP'}{https_ok} ) ) {

        $self->{client} = 'LWP';
        $self->_setup_lwp;

    } elsif ( $env->{'curl'} ) {

        $self->{client} = 'curl';

    } elsif ( $env->{'HTTP::Tiny'} and ( ( ! $self->{https} ) or $env->{'HTTP::Tiny'}{ssl} ) ) {

        $self->{client} = 'HTTP::Tiny';
        $self->_setup_tiny;

    } else {
        croak "Can't determine HTTP client.";
    }
}

sub _setup_furl {
    my $self = shift;

    require Furl;
    $self->{agent} = Furl->new;
}

sub _setup_lwp {
    my $self = shift;

    require LWP::UserAgent;
    $self->{agent} = LWP::UserAgent->new;
    $self->{agent}->env_proxy;
}

sub _setup_curl {
    # do nothing now.
}

sub _setup_tiny {
    my $self = shift;

    require HTTP::Tiny;
    $self->{agent} = HTTP::Tiny->new;
}

sub get {
    my ( $self, $uri ) = @_;

    $self->_validate_uri( $uri );

    my $method = '_get_' . $HTTP_CLIENTS->{$self->{client}}{id};

    return $self->$method( $uri );
}

sub _validate_uri {
    my ( $self, $uri ) = @_;

    if ( ! $uri ) {
        croak "URI isn't set.";
    }

    if ( ( ! $self->{https} ) and $uri =~ /^https:/ ) {
        croak "Can't use 'https' uri.";
    }

    return $self;
}

sub _get_furl {
    my ( $self, $uri ) = @_;

    my $res = $self->{agent}->get( $uri );

    return unless $res;

    my $content_type;
    if ( $res->is_success ) {
        my @ct = split( /;/, $res->content_type );

        $content_type = $ct[0];
    } 

    return HTTP::Client::Any::Response->new(
            client          =>  'Furl',
            status_code     =>  sub { $res->status     },
            is_success      =>  sub { $res->is_success },
            content_type    =>  sub { $content_type if $res->is_success },
            content         =>  sub { $res->content if $res->is_success },
            response        =>  $res,
            );
}

sub _get_lwp {
    my ( $self, $uri ) = @_;

    my $res = $self->{agent}->get( $uri );

    return unless $res;

    return HTTP::Client::Any::Response->new(
            client          =>  'LWP',
            status_code     =>  sub { $res->status       },
            is_success      =>  sub { $res->is_success   },
            content_type    =>  sub { $res->content_type if $res->is_success },
            content         =>  sub { $res->content      if $res->is_success },
            response        =>  $res,
            );
}

sub _get_curl {
    my ( $self, $uri ) = @_;

    my $fh = File::Temp->new;
    my $filename = $fh->filename;

    my $cmd = "curl $uri -o $filename -s -w '%{http_code}:%{content_type}\n'";

    my( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
                run( command => $cmd, verbose => 0 );

    my $content = do { local $/; <$fh> };
    return unless $success;

    my @headers = split( /:/, $stdout_buf->[0] );
    my $status = $headers[0];
    my @ct = split( /;/, $headers[1] );
    my $content_type = $ct[0];

    my $is_success = substr( $status, 0, 1 ) eq '2';
    return HTTP::Client::Any::Response->new(
            client          =>  'curl',
            status_code     =>  sub { $status                        },
            is_success      =>  sub { $is_success                    },
            content_type    =>  sub { $content_type if $is_success   },
            content         =>  sub { $content if $is_success        },
            response        =>  undef,
            );
}

sub _get_tiny {
    my ( $self, $uri ) = @_;

    my $res = $self->{agent}->get( $uri );

    return unless $res;

    my $content_type;
    if ( $res->{success} ) {
        my @ct = split( /;/, $res->{headers}{'content-type'} );

        $content_type = $ct[0];
    } 

    return HTTP::Client::Any::Response->new(
            client          =>  'HTTP::Tiny',
            status_code     =>  sub { $res->{status}                     }, 
            is_success      =>  sub { $res->{success}                    },
            content_type    =>  sub { $content_type if $res->{success}   },
            content         =>  sub { $res->{content} if $res->{success} },
            response        =>  $res,
            );
}

sub __check_env {

    for my $client ( keys %{ $HTTP_CLIENTS } ) {

        if ( $HTTP_CLIENTS->{$client}{type} eq 'module' ) {

            $env->{$client}{available} =
                check_install( module => $HTTP_CLIENTS->{$client}{type} );

            if ( $HTTP_CLIENTS->{$client}{https} ) {

                $env->{$client}{https_ok} = grep { 
                        check_install( module => $_ )
                    } @{ $HTTP_CLIENTS->{$client}{https} };
                
            }

        } else {
            $env->{$client}{available} =
                can_run( $HTTP_CLIENTS->{$client}{command} );

            $env->{$client}{https_ok}++;
        }

    }

}

package HTTP::Client::Any::Response;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {
        client          =>  undef,
        status_code     =>  undef,
        is_success      =>  undef,
        content_type    =>  undef,
        content         =>  undef,
        response        =>  undef,
        @_,
    };

    bless $self, $class;

    return $self;
}

sub client {
    return $_[0]->{client};
}

sub status_code {
    return $_[0]->{status_code}->();
}

sub is_success {
    return $_[0]->{is_success}->();
}

sub content_type {
    return $_[0]->{content_type}->();
}

sub content {
    return $_[0]->{content}->();
}

sub response {
    return $_[0]->{response} ? $_[0]->{response} : undef;
}

1;

=head1 NAME

HTTP::Client::Any - Generic HTTP client interface

=cut
